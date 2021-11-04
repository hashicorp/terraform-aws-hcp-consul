package test

import (
	"net/http"
	"net/url"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/hashicorp/consul/api"
	"github.com/stretchr/testify/require"
)

func TestTerraform_EC2DemoExample(t *testing.T) {
	r := require.New(t)

	tmpDir, err := CreateTestTerraform(t, "../examples/hcp-ec2-demo")
	r.NoError(err)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: tmpDir,
		Vars: map[string]interface{}{
			"cluster_id": "test-ec2",
			"hvn_id":     "test-ec2",
		},
		NoColor: true,
	})

	t.Cleanup(func() {
		terraform.Destroy(t, terraformOptions)
	})

	terraform.InitAndApply(t, terraformOptions)

	aclToken := terraform.Output(t, terraformOptions, "consul_root_token")

	client := &http.Client{}
	r.Eventually(func() bool {
		req, err := http.NewRequest("GET", terraform.Output(t, terraformOptions, "nomad_url"), nil)
		req.SetBasicAuth("nomad", aclToken)
		resp, err := client.Do(req)
		// We really just care that the service is reachable
		if err != nil {
			return false
		}
		resp.Body.Close()
		return true
	}, 10*time.Minute, 10*time.Second)

	consulUrl := terraform.Output(t, terraformOptions, "consul_url")
	parsedURL, err := url.Parse(consulUrl)
	r.NoError(err)

	c := &api.Config{
		Address: parsedURL.Host,
		Scheme:  parsedURL.Scheme,
		Token:   aclToken,
	}
	consul, err := api.NewClient(c)
	r.NoError(err)

	r.Eventually(func() bool {
		svcs, _, err := consul.Catalog().Services(nil)
		if err != nil {
			t.Logf("failed to query Consul services: %s", err)
			return false
		}

		// We expect 13 total services:
		//   1 for the Consul servers
		//   1 for the Nomad servers
		//   1 for the Nomand clients
		//   10 for the 5 services with their sidecars
		if len(svcs) == 13 {
			return true
		}

		var registered []string
		for k := range svcs {
			registered = append(registered, k)
		}
		t.Logf("unexpected number of services registered: %v", registered)
		return false
	}, 10*time.Minute, 10*time.Second)

	r.Eventually(func() bool {
		resp, err := http.Get(terraform.Output(t, terraformOptions, "hashicups_url"))
		// We really just care that the service is reachable
		if err != nil {
			return false
		}
		resp.Body.Close()
		return true
	}, 2*time.Minute, 10*time.Second)
}

func TestTerraform_EKSDemoExample(t *testing.T) {
	r := require.New(t)

	tmpDir, err := CreateTestTerraform(t, "../examples/hcp-eks-demo")
	r.NoError(err)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: tmpDir,
		Vars: map[string]interface{}{
			"cluster_id": "test-eks",
			"hvn_id":     "test-eks",
		},
		NoColor: true,
	})

	t.Cleanup(func() {
		terraform.Destroy(t, terraformOptions)
	})

	terraform.InitAndApply(t, terraformOptions)

	aclToken := terraform.Output(t, terraformOptions, "consul_root_token")
	consulURL := terraform.Output(t, terraformOptions, "consul_url")
	parsedURL, err := url.Parse(consulURL)
	r.NoError(err)

	c := &api.Config{
		Address: parsedURL.Host,
		Scheme:  parsedURL.Scheme,
		Token:   aclToken,
	}
	consul, err := api.NewClient(c)
	r.NoError(err)

	r.Eventually(func() bool {
		svcs, _, err := consul.Catalog().Services(nil)
		if err != nil {
			t.Logf("failed to query Consul services: %s", err)
			return false
		}

		// We expect 6 total services, 1 for the Consul service, 1 for the ingress
		// gateway, and 2 each for counting and dashboard service.
		if len(svcs) == 6 {
			return true
		}

		var registered []string
		for k := range svcs {
			registered = append(registered, k)
		}
		t.Logf("unexpected number of services registered: %v", registered)
		return false
	}, 1*time.Minute, 5*time.Second)

	dashboardURL := terraform.Output(t, terraformOptions, "dashboard_url")
	resp, err := http.Get(dashboardURL)
	// We really just care that the service is reachable
	r.NoError(err)
	resp.Body.Close()
}
