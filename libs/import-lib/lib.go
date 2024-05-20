package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"path"
	"strings"

	uuid "github.com/satori/go.uuid"
	"golang.org/x/exp/slices"
)

func ImportInsomniaV4(filePath string) string {
	fileBytes, err := os.ReadFile(filePath)
	if err != nil {
		log.Println("read insomnia file: ", err)
		return "{}"
	}

	insomnia := new(Insomnia)

	if err := json.Unmarshal(fileBytes, insomnia); err != nil {
		log.Println("unmarshal insomnia file: ", err)
		return "{}"
	}

	workspaces := buildInsomniaTree(insomnia)

	wbytes, err := json.Marshal(workspaces)
	if err != nil {
		log.Println("marshal insomnia object: ", err)
		return "{}"
	}

	return string(wbytes)
}

func ImportPostman(folderPath string) string {
	entities, err := os.ReadDir(folderPath)
	if err != nil {
		return ""
	}

	workSpaces := make([]AppWorkspace, 0)

	for i := range entities {
		entity := entities[i]

		if entity.IsDir() {
			continue
		}

		fileInfo, err := entity.Info()
		if err != nil {
			return "{}"
		}

		fileBytes, err := os.ReadFile(path.Join(folderPath, fileInfo.Name()))
		if err != nil {
			return "{}"
		}

		workSpace := buildPostmanTree(fileBytes)

		if workSpace.Name != "" {
			workSpaces = append(workSpaces, workSpace)
		}
	}

	wbytes, err := json.Marshal(workSpaces)
	if err != nil {
		log.Println("marshal insomnia object: ", err)

		return "{}"
	}

	return string(wbytes)
}

func buildPostmanTree(fileBytes []byte) AppWorkspace {
	var postmanCollection PostmanCollection
	if err := json.Unmarshal([]byte(fileBytes), &postmanCollection); err != nil {
		fmt.Println("Unmarshal postman JSON:", err)

		return AppWorkspace{}
	}

	appWorkspace := convertToAppWorkspace(postmanCollection)

	return appWorkspace
}

func buildInsomniaTree(data *Insomnia) []AppWorkspace {
	// resourceMap := make(map[string]Resource, len(data.Resources))
	workspaces := make([]AppWorkspace, 0)
	folders := make([]*AppFolder, 0)
	queries := make([]AppRequest, 0)

	// for i := range data.Resources {
	// 	resourceMap[data.Resources[i].ID] = data.Resources[i]
	// }

	for i := range data.Resources {
		item := data.Resources[i]

		switch item.Type {
		case Workspace:
			workspaces = append(workspaces, AppWorkspace{
				ID:       item.ID,
				ParentID: item.ParentID,
				Name:     *item.Name,
				Uuid:     uuid.NewV4().String(),
			})
		case Request:
			queries = append(queries, getInsomniaRequest(item))
		case RequestGroup:
			folders = append(folders, &AppFolder{
				ID:       item.ID,
				ParentID: item.ParentID,
				Name:     *item.Name,
				Uuid:     uuid.NewV4().String(),
				NodeType: FolderNode,
			})
		}
	}

	for _, query := range queries {
		idx := slices.IndexFunc(folders, func(f *AppFolder) bool { return f.ID == *query.ParentID })

		// find in folders
		if idx != -1 {
			folders[idx].Requests = append(folders[idx].Requests, query)
			continue
		}

		idx = slices.IndexFunc(workspaces, func(w AppWorkspace) bool { return w.ID == *query.ParentID })

		if idx != -1 {
			workspaces[idx].Items = append(workspaces[idx].Items, &query)
		}
	}

	for _, folder := range folders {
		// find in folders
		if !strings.HasPrefix(*folder.ParentID, "fld") {
			continue
		}

		idx := slices.IndexFunc(folders, func(f *AppFolder) bool { return f.ID == *folder.ParentID })

		if idx != -1 {
			folders[idx].Folders = append(folders[idx].Folders, folder)
		}
	}

	for _, folder := range folders {
		if !strings.HasPrefix(*folder.ParentID, "wrk") {
			continue
		}

		idx := slices.IndexFunc(workspaces, func(w AppWorkspace) bool { return w.ID == *folder.ParentID })

		if idx != -1 {
			workspaces[idx].Items = append(workspaces[idx].Items, folder)
		}
	}

	return workspaces
}
