package test

import (
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/files"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestMultiClusterTerragruntAccount(t *testing.T) {
	t.Parallel()

	exampleDir := "../../examples/multi_clusters/terragrunt/live/prod/aws/us-east-1/my-account/zesty/account"
	tmpDir, err := files.CopyTerraformFolderToTemp(exampleDir, t.Name())
	require.NoError(t, err)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir:    tmpDir,
		TerraformBinary: "terragrunt",
		NoColor:         true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	kompassValues := terraform.Output(t, terraformOptions, "kompass_values_yaml")
	assert.NotEmpty(t, kompassValues, "kompass_values_yaml output should not be empty")
}

func TestMultiClusterTerragruntRunAll(t *testing.T) {
	_ = os.Getenv("ZESTY_API_TOKEN")

	exampleDir := "../../examples/multi_clusters/terragrunt/live/prod/aws/us-east-1/my-account/zesty"
	tmpDir, err := files.CopyTerraformFolderToTemp(exampleDir, t.Name())
	require.NoError(t, err)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir:    tmpDir,
		TerraformBinary: "terragrunt",
		NoColor:         true,
	})

	defer terraform.RunTerraformCommand(t, terraformOptions, "run-all", "destroy", "--terragrunt-non-interactive")

	terraform.RunTerraformCommand(t, terraformOptions, "run-all", "apply", "--terragrunt-non-interactive")
}
