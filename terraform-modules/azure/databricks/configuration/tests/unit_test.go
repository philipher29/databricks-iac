package tests

import (
	"encoding/json"
	"os"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// ---------------------------------------------------------------------------------------------------------------------
// PURE UNIT TESTS
// These tests validate module structure and configuration without requiring Terraform or Databricks
// They can run completely offline with no authentication
// ---------------------------------------------------------------------------------------------------------------------

func TestModuleStructure(t *testing.T) {
	t.Parallel()

	moduleDir := "../"
	requiredFiles := []string{
		"versions.tf",
		"variables.tf",
		"outputs.tf",
		"locals.tf",
		"groups.tf",
		"unity_catalog.tf",
		"catalogs.tf",
		"volumes.tf",
		"cluster_policies.tf",
		"clusters.tf",
		"secret_scopes.tf",
		"ip_access_lists.tf",
		"version.json",
	}

	for _, file := range requiredFiles {
		filePath := filepath.Join(moduleDir, file)
		_, err := os.Stat(filePath)
		assert.NoError(t, err, "Required file %s should exist", file)
	}
}

func TestModuleVersion(t *testing.T) {
	t.Parallel()

	versionFile := "../version.json"
	data, err := os.ReadFile(versionFile)
	require.NoError(t, err, "Should be able to read version.json")

	var version map[string]interface{}
	err = json.Unmarshal(data, &version)
	require.NoError(t, err, "version.json should be valid JSON")

	assert.Contains(t, version, "module")
	assert.Contains(t, version, "version")
	assert.Contains(t, version, "changelog")

	// Verify module name
	assert.Equal(t, "databricks-configuration", version["module"])
}

func TestVersionFormat(t *testing.T) {
	t.Parallel()

	versionFile := "../version.json"
	data, err := os.ReadFile(versionFile)
	require.NoError(t, err)

	var version map[string]interface{}
	err = json.Unmarshal(data, &version)
	require.NoError(t, err)

	versionStr, ok := version["version"].(string)
	require.True(t, ok, "version should be a string")
	assert.Regexp(t, `^\d+\.\d+\.\d+$`, versionStr, "Version should follow semver format X.Y.Z")
}

func TestOutputsExist(t *testing.T) {
	t.Parallel()

	expectedOutputs := []string{
		"groups",
		"storage_credentials",
		"external_locations",
		"catalogs",
		"schemas",
		"volumes",
		"cluster_policies",
		"clusters",
		"secret_scopes",
		"ip_access_lists",
	}

	outputsFile, err := os.ReadFile("../outputs.tf")
	require.NoError(t, err)

	for _, output := range expectedOutputs {
		assert.Contains(t, string(outputsFile), "output \""+output+"\"",
			"outputs.tf should contain output %s", output)
	}
}

func TestVariablesExist(t *testing.T) {
	t.Parallel()

	expectedVariables := []string{
		"workspace_id",
		"groups",
		"catalogs",
		"volumes",
		"cluster_policies",
		"clusters",
		"secret_scopes",
		"ip_access_lists",
	}

	variablesFile, err := os.ReadFile("../variables.tf")
	require.NoError(t, err)

	for _, variable := range expectedVariables {
		assert.Contains(t, string(variablesFile), "variable \""+variable+"\"",
			"variables.tf should contain variable %s", variable)
	}
}

func TestProviderVersionsFile(t *testing.T) {
	t.Parallel()

	versionsFile, err := os.ReadFile("../versions.tf")
	require.NoError(t, err)

	content := string(versionsFile)

	// Should require databricks provider
	assert.Contains(t, content, "databricks", "versions.tf should require databricks provider")

	// Should have terraform version constraint
	assert.Contains(t, content, "required_version", "versions.tf should have terraform version constraint")
}

func TestGroupsTfHasRequiredResources(t *testing.T) {
	t.Parallel()

	groupsFile, err := os.ReadFile("../groups.tf")
	require.NoError(t, err)

	content := string(groupsFile)

	// Should contain group resource
	assert.Contains(t, content, "databricks_group", "groups.tf should define databricks group resource")
	assert.Contains(t, content, "resource \"databricks_group\"", "groups.tf should have group resource block")
}

func TestCatalogsTfHasRequiredResources(t *testing.T) {
	t.Parallel()

	catalogsFile, err := os.ReadFile("../catalogs.tf")
	require.NoError(t, err)

	content := string(catalogsFile)

	// Should contain catalog and schema resources
	assert.Contains(t, content, "databricks_catalog", "catalogs.tf should define databricks catalog resource")
	assert.Contains(t, content, "databricks_schema", "catalogs.tf should define databricks schema resource")
}

func TestUnityCatalogTfHasRequiredResources(t *testing.T) {
	t.Parallel()

	unityCatalogFile, err := os.ReadFile("../unity_catalog.tf")
	require.NoError(t, err)

	content := string(unityCatalogFile)

	// Should contain storage credential and external location resources
	assert.Contains(t, content, "databricks_storage_credential", "unity_catalog.tf should define storage credential resource")
	assert.Contains(t, content, "databricks_external_location", "unity_catalog.tf should define external location resource")
}

func TestClusterPoliciesTfHasRequiredResources(t *testing.T) {
	t.Parallel()

	clusterPoliciesFile, err := os.ReadFile("../cluster_policies.tf")
	require.NoError(t, err)

	content := string(clusterPoliciesFile)

	// Should contain cluster policy resource
	assert.Contains(t, content, "databricks_cluster_policy", "cluster_policies.tf should define cluster policy resource")
}

func TestClustersTfHasRequiredResources(t *testing.T) {
	t.Parallel()

	clustersFile, err := os.ReadFile("../clusters.tf")
	require.NoError(t, err)

	content := string(clustersFile)

	// Should contain cluster resource
	assert.Contains(t, content, "databricks_cluster", "clusters.tf should define databricks cluster resource")
}

func TestSecretScopesTfHasRequiredResources(t *testing.T) {
	t.Parallel()

	secretScopesFile, err := os.ReadFile("../secret_scopes.tf")
	require.NoError(t, err)

	content := string(secretScopesFile)

	// Should contain secret scope resource
	assert.Contains(t, content, "databricks_secret_scope", "secret_scopes.tf should define secret scope resource")
}

func TestVolumesTfHasRequiredResources(t *testing.T) {
	t.Parallel()

	volumesFile, err := os.ReadFile("../volumes.tf")
	require.NoError(t, err)

	content := string(volumesFile)

	// Should contain volume resource
	assert.Contains(t, content, "databricks_volume", "volumes.tf should define volume resource")
}

func TestIPAccessListsTfHasRequiredResources(t *testing.T) {
	t.Parallel()

	ipAccessListsFile, err := os.ReadFile("../ip_access_lists.tf")
	require.NoError(t, err)

	content := string(ipAccessListsFile)

	// Should contain IP access list resource
	assert.Contains(t, content, "databricks_ip_access_list", "ip_access_lists.tf should define IP access list resource")
}

func TestLocalsTfExists(t *testing.T) {
	t.Parallel()

	localsFile, err := os.ReadFile("../locals.tf")
	require.NoError(t, err)

	content := string(localsFile)
	assert.Contains(t, content, "locals {", "locals.tf should have locals block")
}
