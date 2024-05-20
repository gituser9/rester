package main

import (
	"strings"
	"time"

	uuid "github.com/satori/go.uuid"
)

const (
	InsomniaFile          = 1
	PostmanFolder         = 2
	PostmanCollectionFile = 3
)

const (
	FolderNode = 0
	QueryNode  = 1
)

type NodeTyper interface {
	Type() string
}

type AppWorkspace struct {
	ID       string  `json:"-"`
	ParentID *string `json:"-"`
	Name     string  `json:"name"`
	Uuid     string  `json:"uuid"`
	Items    []any   `json:"items"`
}

type AppFolder struct {
	ID       string       `json:"-"`
	ParentID *string      `json:"-"`
	Uuid     string       `json:"uuid"`
	Name     string       `json:"name"`
	Requests []AppRequest `json:"queries"`
	Folders  []*AppFolder `json:"folders,omitempty"`
	NodeType int          `json:"node_type"`
}

type AppRequest struct {
	ID        string            `json:"-"`
	ParentID  *string           `json:"-"`
	Uuid      string            `json:"uuid"`
	Name      string            `json:"name"`
	URL       string            `json:"url"`
	QueryType string            `json:"query_type"`
	BodyType  string            `json:"body_type"`
	Params    []AppRequestParam `json:"params"`
	Headers   map[string]any    `json:"headers"`
	Body      string            `json:"body"`
	NodeType  int               `json:"node_type"`
	FormData  map[string]any    `json:"form_data"`
}

type AppRequestParam struct {
	Name      string `json:"name"`
	Value     string `json:"value"`
	IsEnabled bool   `json:"is_enabled"`
}

func getInsomniaRequest(item Resource) AppRequest {
	query := AppRequest{
		ID:       item.ID,
		ParentID: item.ParentID,
		Uuid:     uuid.NewV4().String(),
		Headers:  map[string]any{},
		Params:   []AppRequestParam{},
		NodeType: QueryNode,
	}

	if item.Name != nil {
		query.Name = *item.Name
	}

	if item.URL != nil {
		query.URL = *item.URL
	}

	if item.Method != nil {
		query.QueryType = *item.Method
	}

	if item.Body != nil && item.Body.Text != nil {
		query.Body = *item.Body.Text
	}

	for _, header := range item.Headers {
		query.Headers[header.Name] = header.Value
	}

	query.BodyType = getInsomniaBodyType(query.Headers)

	for _, param := range item.Parameters {
		query.Params = append(query.Params, AppRequestParam{
			Name:      param.Name,
			Value:     param.Value,
			IsEnabled: !param.Disabled,
		})
	}

	if item.Body.MIMEType != nil && *item.Body.MIMEType == "multipart/form-data" {
		query.FormData = make(map[string]any, len(item.Body.Params))

		for _, param := range item.Body.Params {
			query.FormData[param.Name] = param.Value
		}
	}

	return query
}

func getInsomniaBodyType(headers map[string]any) string {
	hasContentType := false

	typ, ok := headers["Content-Type"]
	if !ok {
		typ, ok = headers["content-type"]
		if ok {
			hasContentType = true
		}
	} else {
		hasContentType = true
	}

	if !hasContentType {
		return "None"
	}

	typeName, ok := typ.(string)
	if !ok {
		return "None"
	}

	typeName = strings.ToLower(typeName)

	switch {
	case strings.Contains(typeName, "json"):
		return "JSON"
	case strings.Contains(typeName, "xml"):
		return "XML"
	case strings.Contains(typeName, "multipart"):
		return "MULTIPART_FORM"
	case strings.Contains(typeName, "x-www-form-urlencoded"):
		return "URL_ENCODED_FORM"
	}

	return "None"
}

func folderToInsomniaResource(fld AppFolder, parentID string) Resource {
	now := time.Now().UnixMilli()

	return Resource{
		ID:                       InsomniaFolderPrefix + uuid.NewV4().String(),
		ParentID:                 &parentID,
		Modified:                 now,
		Created:                  now,
		Name:                     &fld.Name,
		Description:              new(string),
		MetaSortKey:              new(float64),
		Type:                     RequestGroup,
		Environment:              &EnvironmentClass{},
		EnvironmentPropertyOrder: nil,
	}
}

func queryToInsomniaResource(qry AppRequest, parentID string) Resource {
	headers := make([]Header, 0, len(qry.Headers))
	params := make([]Header, 0, len(qry.Params))
	now := time.Now().UnixMilli()
	fls := false
	tr := true
	global := "global"

	for key, value := range qry.Headers {
		headers = append(headers, Header{
			Name:        key,
			Value:       value.(string),
			ID:          new(string),
			Disabled:    false,
			Description: new(string),
		})
	}

	for _, param := range qry.Params {
		params = append(params, Header{
			Name:        param.Name,
			Value:       param.Value,
			ID:          new(string),
			Disabled:    !param.IsEnabled,
			Description: new(string),
		})
	}

	return Resource{
		ID:                              InsomniaQueryPrefix + uuid.NewV4().String(),
		ParentID:                        &parentID,
		Modified:                        now,
		Created:                         now,
		URL:                             &qry.URL,
		Name:                            &qry.Name,
		Description:                     new(string),
		Method:                          &qry.QueryType,
		Body:                            getInsomniaQueryBody(qry),
		Parameters:                      params,
		Headers:                         headers,
		MetaSortKey:                     new(float64),
		IsPrivate:                       &fls,
		SettingStoreCookies:             &tr,
		SettingSendCookies:              &tr,
		SettingDisableRenderRequestBody: &fls,
		SettingEncodeURL:                &tr,
		SettingRebuildPath:              &tr,
		SettingFollowRedirects:          &global,
		Type:                            Request,
	}
}

func buildInsomniaWorkspace(ws AppWorkspace) Resource {
	now := time.Now().UnixMilli()
	collection := "collection"

	return Resource{
		ID:       InsomniaWorkspacePrefix + uuid.NewV4().String(),
		ParentID: nil,
		Created:  now,
		Modified: now,
		Name:     &ws.Name,
		Scope:    &collection,
		Type:     Workspace,
	}
}

func getInsomniaQueryBody(qry AppRequest) *Body {
	if qry.QueryType == "GET" {
		return &Body{}
	}

	if qry.QueryType == "HEAD" {
		return &Body{}
	}

	return &Body{}
}
