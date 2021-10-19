package examples

import (
	"io/fs"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"testing"
)

// The value here is the directory based on relative path from the various
// examples
var localSourceMap = map[string]string{
	"hashicorp/hcp-consul/aws":                         "../..",
	"hashicorp/hcp-consul/aws//modules/hcp-ec2-client": "../../modules/hcp-ec2-client",
	"hashicorp/hcp-consul/aws//modules/hcp-eks-client": "../../modules/hcp-eks-client",
	"hashicorp/hcp-consul/aws//modules/k8s-demo-app":   "../../modules/k8s-demo-app",
}

func CreateTestTerraform(t *testing.T, exampleDir string) (string, error) {
	tmpDir, err := os.MkdirTemp("", filepath.Base(exampleDir))
	if err != nil {
		return "", err
	}
	t.Cleanup(func() {
		os.RemoveAll(tmpDir)
	})

	err = fs.WalkDir(os.DirFS(exampleDir), ".", func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}

		// Only walk the root directory, do not recurse.
		if path != "." && d.IsDir() {
			return fs.SkipDir
		}

		// If terraform file, copy to tmpDir
		if strings.HasSuffix(d.Name(), ".tf") {
			data, err := os.ReadFile(filepath.Join(exampleDir, d.Name()))
			if err != nil {
				return err
			}

			// Change the remote sources to use local sources
			for r, l := range localSourceMap {
				localPath, err := filepath.Abs(filepath.Join(exampleDir, l))
				if err != nil {
					return err
				}
				data = regexp.MustCompile(r).ReplaceAllLiteral(data, []byte(localPath))
			}

			err = os.WriteFile(filepath.Join(tmpDir, d.Name()), data, 0644)
			if err != nil {
				return err
			}
		}
		return nil
	})
	if err != nil {
		return "", err
	}
	return tmpDir, nil
}
