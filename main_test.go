package main

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestServer(t *testing.T) {
	req, err := http.NewRequest("GET", "/TestName", nil)
	if err != nil {
		t.Fatal(err)
	}

	resp := httptest.NewRecorder()
	handler := http.HandlerFunc(sayHelloHandler)
	handler.ServeHTTP(resp, req)

	if resp.Code != http.StatusOK {
		t.Fatalf("Received non-200 response code: %d\n", resp.Code)
	}

	expected := "Hello TestName"
	if resp.Body.String() != expected {
		t.Errorf("Expected: '%s' but received: '%s'\n", expected, resp.Body.String())
	}
}
