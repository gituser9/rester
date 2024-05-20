package main

import "C"

//export Import
func Import(path *C.char, fileType int) *C.char {
	filePath := C.GoString(path)

	if fileType == InsomniaFile {
		jsonString := ImportInsomniaV4(filePath)
		return C.CString(jsonString)
	}

	if fileType == PostmanFolder {
		jsonString := ImportPostman(filePath)
		return C.CString(jsonString)
	}

	return C.CString("{}")
}
