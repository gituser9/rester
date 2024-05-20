package main

type Insomnia struct {
	Type         string     `json:"_type"`
	ExportFormat int64      `json:"__export_format"`
	ExportDate   string     `json:"__export_date"`
	ExportSource string     `json:"__export_source"`
	Resources    []Resource `json:"resources"`
}

type Resource struct {
	ID                              string             `json:"_id"`
	ParentID                        *string            `json:"parentId"`
	Modified                        int64              `json:"modified"`
	Created                         int64              `json:"created"`
	URL                             *string            `json:"url,omitempty"`
	Name                            *string            `json:"name,omitempty"`
	Description                     *string            `json:"description,omitempty"`
	Method                          *string            `json:"method,omitempty"`
	Body                            *Body              `json:"body,omitempty"`
	Parameters                      []Header           `json:"parameters,omitempty"`
	Headers                         []Header           `json:"headers,omitempty"`
	Authentication                  *Authentication    `json:"authentication,omitempty"`
	MetaSortKey                     *float64           `json:"metaSortKey,omitempty"`
	IsPrivate                       *bool              `json:"isPrivate,omitempty"`
	SettingStoreCookies             *bool              `json:"settingStoreCookies,omitempty"`
	SettingSendCookies              *bool              `json:"settingSendCookies,omitempty"`
	SettingDisableRenderRequestBody *bool              `json:"settingDisableRenderRequestBody,omitempty"`
	SettingEncodeURL                *bool              `json:"settingEncodeUrl,omitempty"`
	SettingRebuildPath              *bool              `json:"settingRebuildPath,omitempty"`
	SettingFollowRedirects          *string            `json:"settingFollowRedirects,omitempty"`
	Type                            Type               `json:"_type"`
	Scope                           *string            `json:"scope,omitempty"`
	Environment                     *EnvironmentClass  `json:"environment,omitempty"`
	EnvironmentPropertyOrder        interface{}        `json:"environmentPropertyOrder"`
	Data                            *Data              `json:"data,omitempty"`
	DataPropertyOrder               *DataPropertyOrder `json:"dataPropertyOrder"`
	Color                           interface{}        `json:"color"`
	Cookies                         []Cooky            `json:"cookies,omitempty"`
	FileName                        *string            `json:"fileName,omitempty"`
	Contents                        *string            `json:"contents,omitempty"`
	ContentType                     *string            `json:"contentType,omitempty"`
	Value                           *string            `json:"value,omitempty"`
	Mode                            *string            `json:"mode,omitempty"`
}

type Authentication struct {
	Type     *string `json:"type,omitempty"`
	Token    *string `json:"token,omitempty"`
	Disabled *bool   `json:"disabled,omitempty"`
}

type Body struct {
	MIMEType *string `json:"mimeType,omitempty"`
	Text     *string `json:"text,omitempty"`
	Params   []Param `json:"params,omitempty"`
}

type Param struct {
	Name        string  `json:"name"`
	Value       string  `json:"value"`
	Description string  `json:"description"`
	ID          string  `json:"id"`
	Type        *string `json:"type,omitempty"`
	FileName    *string `json:"fileName,omitempty"`
	Disabled    *bool   `json:"disabled,omitempty"`
}

type Cooky struct {
	Key          string  `json:"key"`
	Value        string  `json:"value"`
	Domain       string  `json:"domain"`
	Path         string  `json:"path"`
	HTTPOnly     *bool   `json:"httpOnly,omitempty"`
	HostOnly     bool    `json:"hostOnly"`
	Creation     string  `json:"creation"`
	LastAccessed string  `json:"lastAccessed"`
	ID           string  `json:"id"`
	Expires      *string `json:"expires,omitempty"`
	Secure       *bool   `json:"secure,omitempty"`
}

type Data struct {
	Host          *string `json:"host,omitempty"`
	PrizmaHost    *string `json:"prizma_host,omitempty"`
	AuthHost      *string `json:"auth_host,omitempty"`
	EventHost     *string `json:"event_host,omitempty"`
	ChartHost     *string `json:"chart_host,omitempty"`
	AnalyticsHost *string `json:"analytics_host,omitempty"`
	UserHost      *string `json:"user_host,omitempty"`
}

type DataPropertyOrder struct {
	Empty []string `json:"&,omitempty"`
}

type EnvironmentClass struct{}

type Header struct {
	Name        string  `json:"name"`
	Value       string  `json:"value"`
	ID          *string `json:"id,omitempty"`
	Disabled    bool    `json:"disabled,omitempty"`
	Description *string `json:"description,omitempty"`
}

type SettingFollowRedirects string

const (
	Global SettingFollowRedirects = "global"
)

type Type string

const (
	APISpec          Type = "api_spec"
	CookieJar        Type = "cookie_jar"
	Environment      Type = "environment"
	Request          Type = "request"
	RequestGroup     Type = "request_group"
	UnitTestSuite    Type = "unit_test_suite"
	WebsocketPayload Type = "websocket_payload"
	Workspace        Type = "workspace"
)

const (
	InsomniaWorkspacePrefix = "wrk_"
	InsomniaFolderPrefix    = "fld_"
	InsomniaQueryPrefix     = "req_"
)
