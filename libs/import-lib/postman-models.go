package main

import uuid "github.com/satori/go.uuid"

type PostmanCollection struct {
	Info PostmanInfo             `json:"info"`
	Item []PostmanCollectionItem `json:"item"`
}

type PostmanInfo struct {
	PostmanID  string `json:"_postman_id"`
	Name       string `json:"name"`
	Schema     string `json:"schema"`
	ExporterID string `json:"_exporter_id"`
}

type PostmanCollectionItem struct {
	Name    string                  `json:"name"`
	Request *PostmanRequest         `json:"request,omitempty"`
	Body    *PostmanBody            `json:"body,omitempty"`
	Item    []PostmanCollectionItem `json:"item,omitempty"`
}

type ProtocolProfileBehavior struct {
	DisableBodyPruning bool `json:"disableBodyPruning"`
}

type PostmanRequest struct {
	Method string          `json:"method"`
	Header []PostmanHeader `json:"header,omitempty"`
	Body   *PostmanBody    `json:"body,omitempty"`
	URL    PostmanURL      `json:"url"`
}

type PostmanBody struct {
	Mode     string          `json:"mode"`
	Raw      *string         `json:"raw,omitempty"`
	Options  *PostmanOptions `json:"options,omitempty"`
	Formdata []PostmanHeader `json:"formdata,omitempty"`
}

type PostmanHeader struct {
	Key      string  `json:"key"`
	Type     *string `json:"type,omitempty"`
	Src      *string `json:"src,omitempty"`
	Value    *string `json:"value,omitempty"`
	Disabled *bool   `json:"disabled,omitempty"`
}

type PostmanOptions struct {
	Raw RawClass `json:"raw"`
}

type RawClass struct {
	Language string `json:"language"`
}

type PostmanURL struct {
	Raw   string   `json:"raw"`
	Host  []string `json:"host"`
	Path  []string `json:"path"`
	Query []Header `json:"query,omitempty"`
}

// Конвертация из Collection в AppWorkspace
func convertToAppWorkspace(collection PostmanCollection) AppWorkspace {
	appWorkspace := AppWorkspace{
		Name:  collection.Info.Name,
		Uuid:  uuid.NewV4().String(),
		Items: make([]any, len(collection.Item)),
	}

	for i, item := range collection.Item {
		if len(item.Item) != 0 {
			appWorkspace.Items[i] = convertToAppFolder(item)
		} else {
			appWorkspace.Items[i] = convertToAppRequest(item)
		}

	}

	return appWorkspace
}

// Конвертация из Item в AppFolder
func convertToAppFolder(item PostmanCollectionItem) AppFolder {
	appFolder := AppFolder{
		Name:     item.Name,
		Uuid:     uuid.NewV4().String(),
		NodeType: FolderNode,
	}

	for _, it := range item.Item {
		if it.Request != nil {
			appFolder.Requests = append(appFolder.Requests, convertToAppRequest(it))
		} else {
			fld := convertToAppFolder(it)
			appFolder.Folders = append(appFolder.Folders, &fld)
		}
	}

	return appFolder
}

// Конвертация из Request в AppRequest
func convertToAppRequest(item PostmanCollectionItem) AppRequest {
	appRequest := AppRequest{
		Name:      item.Name,
		Uuid:      uuid.NewV4().String(),
		URL:       item.Request.URL.Raw,
		QueryType: item.Request.Method,
		BodyType:  getBodyTypeFromPostmanItem(item),
		Params:    make([]AppRequestParam, 0, len(item.Request.URL.Query)),
		Headers:   make(map[string]any),
		NodeType:  QueryNode,
	}

	if item.Request.Body != nil && item.Request.Body.Raw != nil {
		appRequest.Body = *item.Request.Body.Raw
	}

	for _, param := range item.Request.URL.Query {
		appRequest.Params = append(appRequest.Params, AppRequestParam{
			Name:      param.Name,
			Value:     param.Value,
			IsEnabled: !param.Disabled,
		})
	}

	for _, header := range item.Request.Header {
		appRequest.Headers[header.Key] = header.Value
	}

	if item.Request.Body != nil && item.Request.Body.Formdata != nil {
		appRequest.FormData = make(map[string]any)

		for _, fd := range item.Request.Body.Formdata {
			if fd.Value != nil {
				appRequest.FormData[fd.Key] = *fd.Value
			}
			if fd.Src != nil {
				appRequest.FormData[fd.Key] = "file://" + *fd.Src
			}
		}
	}

	return appRequest
}

func getBodyTypeFromPostmanItem(item PostmanCollectionItem) string {
	if item.Body == nil {
		return "None"
	}

	if item.Body.Mode == "formdata" {
		return "MULTIPART_FORM"
	}

	if item.Body.Options != nil {
		if item.Body.Options.Raw.Language == "json" {
			return "JSON"
		}
	}

	return "None"
}
