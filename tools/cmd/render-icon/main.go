package main

import (
	"fmt"
	"strconv"

	"github.com/castdrian/CursorProMax/tools/internal/repo"
)

var pointSizes = []int{16, 32, 128, 256, 512}

func render(source, destination string, pixels int) {
	side := strconv.Itoa(pixels)
	if err := repo.Run(repo.Root(), "resvg", "-w", side, "-h", side, source, destination); err != nil {
		repo.Fail(err)
	}
}

func main() {
	source := repo.Path("assets", "AppIcon.svg")
	iconSet := repo.Path("CursorProMax", "Resources", "Assets.xcassets", "AppIcon.appiconset")
	for _, size := range pointSizes {
		render(source, fmt.Sprintf("%s/icon_%dx%d.png", iconSet, size, size), size)
		render(source, fmt.Sprintf("%s/icon_%dx%d@2x.png", iconSet, size, size), size*2)
	}
}
