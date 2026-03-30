package test

import (
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/files"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestSimpleExample(t *testing.T) {
	t.Parallel()

	clusterName := os.Getenv("CLUSTER_NAME")
	require.NotEmpty(t, clusterName, "CLUSTER_NAME environment variable must be set")

	exampleDir := "../../examples/simple-terraform"
	tmpDir, err := files.CopyTerraformFolderToTemp(exampleDir, t.Name())
	require.NoError(t, err)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: tmpDir,
		Vars: map[string]interface{}{
			"cluster_name": clusterName,
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	kompassValues := terraform.Output(t, terraformOptions, "kompass_values_yaml")
	assert.NotEmpty(t, kompassValues, "kompass_values_yaml output should not be empty")
}

func TestSimpleExamplePlanOnly(t *testing.T) {
	t.Parallel()

	clusterName := os.Getenv("CLUSTER_NAME")
	require.NotEmpty(t, clusterName, "CLUSTER_NAME environment variable must be set")

	exampleDir := "../../examples/simple-terraform"
	tmpDir, err := files.CopyTerraformFolderToTemp(exampleDir, t.Name())
	require.NoError(t, err)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: tmpDir,
		Vars: map[string]interface{}{
			"cluster_name": clusterName,
		},
		NoColor: true,
	})

	terraform.InitAndPlan(t, terraformOptions)
}
