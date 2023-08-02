package packs

import (
	"context"
	"fmt"
	"os"
	"testing"

	"knative.dev/func/pkg/builders/buildpacks"
	fn "knative.dev/func/pkg/functions"
)

const Registry = "ghcr.io/boson-project"

type testCase struct {
	Name       string
	Runtime    string
	Templates  []string
	Buildpacks []string
	Builder    string
}

func testCases(version string) []testCase {
	return []testCase{
		{
			Name: "Go function buildpack",
			Buildpacks: []string{
				"paketo-buildpacks/go-dist",
				fmt.Sprintf("ghcr.io/boson-project/go-function-buildpack:%s", version),
			},
			Builder:   "gcr.io/paketo-buildpacks/builder:base",
			Runtime:   "go",
			Templates: []string{"cloudevents", "http"},
		},
		{
			Name:       "Go function builder",
			Builder:    fmt.Sprintf("ghcr.io/boson-project/go-function-builder:%s", version),
			Buildpacks: []string{},
			Runtime:    "go",
			Templates:  []string{"cloudevents", "http"},
		},
	}
}

func TestPacksTable(t *testing.T) {
	version, found := os.LookupEnv("VERSION_TAG")
	if !found {
		version = "tip"
	}
	t.Logf("Version under test: %v", version)

	for _, tc := range testCases(version) {
		tc := tc
		for _, tpl := range tc.Templates {
			tpl := tpl
			root := fmt.Sprintf("%s/%s/%s", "testdata", tc.Runtime, tpl)
			t.Run(fmt.Sprintf("%s %s", tc.Name, tpl), func(t *testing.T) {
				defer using(t, root)()

				client := fn.New(
					fn.WithRegistry(Registry),
					fn.WithBuilder(buildpacks.NewBuilder()),
					fn.WithVerbose(true),
				)

				// Create a new project using the client
				f := fn.Function{
					Name:     "fn",
					Root:     root,
					Runtime:  tc.Runtime,
					Template: tpl,
					Build: fn.BuildSpec{
						Buildpacks: tc.Buildpacks,
						Builder:    tc.Builder,
					},
				}

				err := f.Write()
				if err != nil {
					t.Fatal(err)
				}
				f, err = client.Build(context.Background(), f)
				if err != nil {
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
