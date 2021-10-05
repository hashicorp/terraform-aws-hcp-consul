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
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/hcp-ec2-demo",
		Vars: map[string]interface{}{
			"cluster_id": "test-ec2-example",
		},
		NoColor: true,
	})

	t.Cleanup(func() {
		terraform.Destroy(t, terraformOptions)
	})

	terraform.InitAndApply(t, terraformOptions)

	aclToken := terraform.Output(t, terraformOptions, "consul_root_token")
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

		// We expect 5 total services, 1 for the Consul service, and 2 each for
		// counting and dashboard service.
		if len(svcs) == 5 {
			return true
		}

		var registered []string
		for k := range svcs {
			registered = append(registered, k)
		}
		t.Logf("unexpected number of services registered: %v", registered)
		return false
	}, 2*time.Minute, 10*time.Second)

	var clients struct {
		CountingURL  string `json:"counting_url"`
		DashboardURL string `json:"dashboard_url"`
	}
	terraform.OutputStruct(t, terraformOptions, "clients", &clients)

	resp, err := http.Get(clients.CountingURL)
	// We really just care that the service is reachable
	r.NoError(err)
	resp.Body.Close()

	resp, err = http.Get(clients.DashboardURL)
	// We really just care that the service is reachable
	r.NoError(err)
	resp.Body.Close()
}

func TestTerraform_EKSDemoExample(t *testing.T) {
	r := require.New(t)
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/hcp-eks-demo",
		Vars: map[string]interface{}{
			"cluster_id": "test-eks-example",
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
