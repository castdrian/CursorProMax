package main

import (
	"fmt"
	"os/exec"
	"strings"

	"github.com/castdrian/CursorProMax/tools/internal/repo"
)

type step struct {
	name      string
	directory string
	command   []string
	optional  bool
}

func main() {
	steps := []step{
		{name: "xcodegen", command: []string{"xcodegen", "generate", "--quiet"}},
		{name: "build and test", command: []string{"xcodebuild", "-project", "CursorProMax.xcodeproj", "-scheme", "CursorProMax", "-destination", "platform=macOS", "-quiet", "build", "test", "CODE_SIGNING_ALLOWED=NO"}},
		{name: "go vet", directory: repo.Path("tools"), command: []string{"go", "vet", "./..."}},
		{name: "actionlint", command: []string{"actionlint"}, optional: true},
	}
	var skipped []string
	for _, current := range steps {
		if _, err := exec.LookPath(current.command[0]); err != nil && current.optional {
			skipped = append(skipped, current.name)
			continue
		}
		fmt.Printf("==> %s\n", current.name)
		directory := current.directory
		if directory == "" {
			directory = repo.Root()
		}
		if err := repo.Run(directory, current.command[0], current.command[1:]...); err != nil {
			repo.Fail(fmt.Errorf("%s failed", current.name))
		}
	}
	if len(skipped) > 0 {
		fmt.Printf("Skipped (not installed): %s\n", strings.Join(skipped, ", "))
	}
	fmt.Println("Preflight passed")
}
