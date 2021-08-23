package packs

import (
	"context"
	"fmt"
	"os"
	"testing"

	fn "knative.dev/kn-plugin-func"
	"knative.dev/kn-plugin-func/buildpacks"
)

const Registry = "ghcr.io/boson-project"

type templates []string
type testCase struct {
	Name       string
	Runtime    string
	Templates  []string
	Buildpacks []string
}

func testCases(version string) []testCase {
	return []testCase{
		{
			Name: "Go function buildpack",
			Buildpacks: []string{
				fmt.Sprintf("ghcr.io/boson-project/go-function-buildpack:%s", version),
				"paketo-buildpacks/go-dist",
			},
			Runtime:   "go",
			Templates: []string{"events", "http"},
		},
		{
			Name: "TypeScript function buildpack",
			Buildpacks: []string{
				fmt.Sprintf("ghcr.io/boson-project/typescript-function-buildpack:%s", version),
				"paketo-buildpacks/nodejs",
			},
			Runtime:   "typescript",
			Templates: []string{"events", "http"},
		},
	}
}

func TestPacksTable(t *testing.T) {
	version, found := os.LookupEnv("VERSION_TAG")
	if !found {
		version = "tip"
	}
	t.Logf("Buildpack image version under test: %v", version)

	for _, tc := range testCases(version) {
		for _, tpl := range tc.Templates {
			root := fmt.Sprintf("%s/%s/%s", "testdata", tc.Runtime, tpl)
			t.Run(root, func(t *testing.T) {
				defer using(t, root)()

				client := fn.New(
					fn.WithRegistry(Registry),
					fn.WithBuilder(buildpacks.NewBuilder()),
					fn.WithVerbose(true),
				)

				// Create a new project using the client
				funk := fn.Function{
					Root:       root,
					Runtime:    tc.Runtime,
					Template:   tpl,
					Buildpacks: tc.Buildpacks,
				}
				if err := client.Create(funk); err != nil {
					t.Fatal(err)
				}
				if err := client.Build(context.Background(), funk.Root); err != nil {
					t.Fatal(err)
				}
			})
		}
	}
}

// USING:  Make specified dir.  Return deferrable cleanup fn.
func using(t *testing.T, root string) func() {
	t.Helper()
	mkdir(t, root)
	return func() {
		rm(t, root)
	}
}

func mkdir(t *testing.T, dir string) {
	t.Helper()
	if err := os.MkdirAll(dir, 0700); err != nil {
		t.Fatal(err)
	}
}

func rm(t *testing.T, dir string) {
	t.Helper()
	if err := os.RemoveAll(dir); err != nil {
		t.Fatal(err)
	}
}
