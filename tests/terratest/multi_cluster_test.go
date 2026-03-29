package test

import (
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/files"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestMultiClusterAccountExample(t *testing.T) {
	t.Parallel()

	exampleDir := "../../examples/multi_clusters/terraform/account"
	tmpDir, err := files.CopyTerraformFolderToTemp(exampleDir, t.Name())
	require.NoError(t, err)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: tmpDir,
		NoColor:      true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	kompassValues := terraform.Output(t, terraformOptions, "kompass_values_yaml")
	assert.NotEmpty(t, kompassValues, "kompass_values_yaml output should not be empty")
}

func TestMultiClusterKompassExample(t *testing.T) {
	t.Parallel()

	clusterName := os.Getenv("CLUSTER_NAME")
	require.NotEmpty(t, clusterName, "CLUSTER_NAME environment variable must be set")

	exampleDir := "../../examples/multi_clusters/terraform/kompass-eks-prod"
	tmpDir, err := files.CopyTerraformFolderToTemp(exampleDir, t.Name())
	require.NoError(t, err)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: tmpDir,
		NoColor:      true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)
}

func TestMultiClusterFullE2E(t *testing.T) {
	clusterName := os.Getenv("CLUSTER_NAME")
	require.NotEmpty(t, clusterName, "CLUSTER_NAME environment variable must be set")

	accountDir := "../../examples/multi_clusters/terraform/account"
	accountTmpDir, err := files.CopyTerraformFolderToTemp(accountDir, t.Name()+"-account")
	require.NoError(t, err)

	accountOpts := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: accountTmpDir,
		NoColor:      true,
	})

	defer terraform.Destroy(t, accountOpts)
	terraform.InitAndApply(t, accountOpts)

	kompassValues := terraform.Output(t, accountOpts, "kompass_values_yaml")
	assert.NotEmpty(t, kompassValues, "account layer should output kompass_values_yaml")

	kompassDir := "../../examples/multi_clusters/terraform/kompass-eks-prod"
	kompassTmpDir, err := files.CopyTerraformFolderToTemp(kompassDir, t.Name()+"-kompass")
	require.NoError(t, err)

	kompassOpts := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: kompassTmpDir,
		NoColor:      true,
	})

	defer terraform.Destroy(t, kompassOpts)
	terraform.InitAndApply(t, kompassOpts)
}
