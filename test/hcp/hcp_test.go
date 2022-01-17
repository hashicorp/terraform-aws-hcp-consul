package hcp

import (
	"bytes"
	"flag"
	"os"
	"path/filepath"
	"testing"
	"text/template"

	"github.com/stretchr/testify/require"
)

type HCPTemplate struct {
	VPCRegion           string
	HVNRegion           string
	VPCID               string
	ClusterID           string
	PublicRouteTableID  string
	PrivateRouteTableID string
	PublicSubnet1       string
	PublicSubnet2       string
	PrivateSubnet1      string
	PrivateSubnet2      string
}

const (
	hcpRootDir = "../../hcp-ui-templates"
)

// update allows golden files to be updated based on the current output.
var update = flag.Bool("update", false, "update golden files")

func TestHCPTemplates(t *testing.T) {
	cases := []struct {
		name           string
		templatePath   string
		templateValues HCPTemplate
	}{
		{
			name:         "ec2",
			templatePath: filepath.Join(hcpRootDir, "ec2", "main.tf"),
			templateValues: HCPTemplate{
				VPCRegion: "us-west-2",
				HVNRegion: "us-west-2",
				ClusterID: "consul-quickstart-1634271483588",
			},
		},
		{
			name:         "ec2-existing-vpc",
			templatePath: filepath.Join(hcpRootDir, "ec2-existing-vpc", "main.tf"),
			templateValues: HCPTemplate{
				VPCRegion:          "us-east-1",
				HVNRegion:          "us-west-2",
				ClusterID:          "consul-quickstart-2634271483588",
				VPCID:              "vpc-071d21e09127bb012",
				PublicRouteTableID: "rtb-02b0b92efeae83c28",
				PublicSubnet1:      "subnet-04afc1709a875ad5d",
			},
		},
		{
			name:         "eks",
			templatePath: filepath.Join(hcpRootDir, "eks", "main.tf"),
			templateValues: HCPTemplate{
				VPCRegion: "us-west-2",
				HVNRegion: "us-west-2",
				ClusterID: "consul-quickstart-3634271483588",
			},
		},
		{
			name:         "eks-existing-vpc",
			templatePath: filepath.Join(hcpRootDir, "eks-existing-vpc", "main.tf"),
			templateValues: HCPTemplate{
				VPCRegion:          "eu-west-1",
				HVNRegion:          "eu-west-2",
				ClusterID:          "consul-quickstart-4634271483588",
				VPCID:              "vpc-171d21e09127bb012",
				PublicRouteTableID: "rtb-12b0b92efeae83c28",
				PublicSubnet1:      "subnet-14afc1709a875ad5d",
				PublicSubnet2:      "subnet-1aa8d55f44387908d",
			},
		},
		{
			name:         "ecs",
			templatePath: filepath.Join(hcpRootDir, "ecs", "main.tf"),
			templateValues: HCPTemplate{
				VPCRegion: "us-west-2",
				HVNRegion: "us-west-2",
				ClusterID: "consul-quickstart-3634271483588",
			},
		},
		{
			name:         "ecs-existing-vpc",
			templatePath: filepath.Join(hcpRootDir, "ecs-existing-vpc", "main.tf"),
			templateValues: HCPTemplate{
				VPCRegion:           "eu-west-1",
				HVNRegion:           "eu-west-2",
				ClusterID:           "consul-quickstart-4634271483588",
				VPCID:               "vpc-171d21e09127bb012",
				PublicRouteTableID:  "rtb-12b0b92efeae83c28",
				PrivateRouteTableID: "rtb-32b0b92efeae83c30",
				PublicSubnet1:       "subnet-14afc1709a875ad5d",
				PublicSubnet2:       "subnet-1aa8d55f44387908d",
				PrivateSubnet1:      "subnet-44afc1709a875ad5d",
				PrivateSubnet2:      "subnet-5aa8d55f44387908d",
			},
		},
	}

	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			r := require.New(t)
			temp, err := template.ParseFiles(c.templatePath)
			r.NoError(err)

			var buf bytes.Buffer
			r.NoError(temp.Execute(&buf, c.templateValues))

			r.Equal(golden(t, c.name, buf.String()), buf.String())
		})
	}
}

// golden returns the byte array of the requested golden file, in order to
// compare against the test-generated value. If the -update flag was passed,
// this also updates the golden file itself.
func golden(t *testing.T, name string, got string) string {
	t.Helper()

	golden := filepath.Join("testdata", name+".golden")

	// Update the golden file if the update flag was passed in.
	if *update && len(got) != 0 {
		require.NoError(t, os.WriteFile(golden, []byte(got), 0644))
		return got
	}

	data, err := os.ReadFile(golden)
	require.NoError(t, err)

	return string(data)
}
