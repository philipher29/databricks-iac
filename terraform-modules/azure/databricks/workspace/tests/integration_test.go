package tests

import (
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// ---------------------------------------------------------------------------------------------------------------------
// INTEGRATION TESTS
// These tests deploy real resources to Azure - only run in CI/CD or with explicit flag
// Set INTEGRATION_TEST=true to run these tests
// Required environment variables: ARM_SUBSCRIPTION_ID, ARM_TENANT_ID, ARM_CLIENT_ID, ARM_CLIENT_SECRET
// Or use Azure CLI authentication (az login)
// ---------------------------------------------------------------------------------------------------------------------

func skipIfNotIntegration(t *testing.T) {
	if os.Getenv("INTEGRATION_TEST") != "true" {
		t.Skip("Skipping integration test. Set INTEGRATION_TEST=true to run.")
	}
}

// TestIntegrationWorkspaceDeployment deploys a real workspace and validates it
func TestIntegrationWorkspaceDeployment(t *testing.T) {
	skipIfNotIntegration(t)
	t.Parallel()

	// Generate unique names to avoid conflicts
	uniqueID := random.UniqueId()
	resourceGroupName := fmt.Sprintf("rg-dbw-test-%s", uniqueID)
	workspaceName := fmt.Sprintf("dbw-test-%s", uniqueID)
	location := "westeurope"

	// Get Azure subscription from environment
	subscriptionID := os.Getenv("ARM_SUBSCRIPTION_ID")
	require.NotEmpty(t, subscriptionID, "ARM_SUBSCRIPTION_ID must be set")

	// Use a helper Terraform configuration to create the resource group
	// This is cleaner than using Azure SDK directly
	rgTerraformOptions := createResourceGroupTerraformOptions(t, resourceGroupName, location)
	defer terraform.Destroy(t, rgTerraformOptions)
	terraform.InitAndApply(t, rgTerraformOptions)

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"name":                workspaceName,
			"resource_group_name": resourceGroupName,
			"location":            location,
			"sku":                 "premium",
			"access_connector": map[string]interface{}{
				"create":        true,
				"identity_type": "SystemAssigned",
			},
			"tags": map[string]interface{}{
				"Environment": "test",
				"Purpose":     "integration-test",
				"Timestamp":   time.Now().Format(time.RFC3339),
			},
		},
		NoColor: true,
	}

	// Ensure cleanup
	defer terraform.Destroy(t, terraformOptions)

	// Deploy
	terraform.InitAndApply(t, terraformOptions)

	// Validate outputs
	workspaceID := terraform.Output(t, terraformOptions, "workspace_id")
	assert.NotEmpty(t, workspaceID, "workspace_id should be set")

	workspaceURL := terraform.Output(t, terraformOptions, "workspace_url")
	assert.NotEmpty(t, workspaceURL, "workspace_url should be set")
	assert.Contains(t, workspaceURL, ".azuredatabricks.net")

	accessConnectorID := terraform.Output(t, terraformOptions, "access_connector_id")
	assert.NotEmpty(t, accessConnectorID, "access_connector_id should be set")

	accessConnectorPrincipalID := terraform.Output(t, terraformOptions, "access_connector_principal_id")
	assert.NotEmpty(t, accessConnectorPrincipalID, "access_connector_principal_id should be set")
}

// TestIntegrationWorkspaceWithVNetInjection tests VNet injection configuration
func TestIntegrationWorkspaceWithVNetInjection(t *testing.T) {
	skipIfNotIntegration(t)
	t.Parallel()

	// This test requires pre-existing VNet infrastructure
	// Skip if VNet details not provided
	vnetID := os.Getenv("TEST_VNET_ID")
	privateSubnet := os.Getenv("TEST_PRIVATE_SUBNET")
	publicSubnet := os.Getenv("TEST_PUBLIC_SUBNET")
	nsgID := os.Getenv("TEST_NSG_ID")

	if vnetID == "" || privateSubnet == "" || publicSubnet == "" || nsgID == "" {
		t.Skip("Skipping VNet injection test. Set TEST_VNET_ID, TEST_PRIVATE_SUBNET, TEST_PUBLIC_SUBNET, TEST_NSG_ID")
	}

	uniqueID := random.UniqueId()
	resourceGroupName := fmt.Sprintf("rg-dbw-vnet-test-%s", uniqueID)
	workspaceName := fmt.Sprintf("dbw-vnet-test-%s", uniqueID)
	location := "westeurope"

	subscriptionID := os.Getenv("ARM_SUBSCRIPTION_ID")
	require.NotEmpty(t, subscriptionID)

	// Create resource group using Terraform
	rgTerraformOptions := createResourceGroupTerraformOptions(t, resourceGroupName, location)
	defer terraform.Destroy(t, rgTerraformOptions)
	terraform.InitAndApply(t, rgTerraformOptions)

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"name":                          workspaceName,
			"resource_group_name":           resourceGroupName,
			"location":                      location,
			"sku":                           "premium",
			"public_network_access_enabled": false,
			"custom_vnet_config": map[string]interface{}{
				"virtual_network_id":                       vnetID,
				"private_subnet_name":                      privateSubnet,
				"private_subnet_network_security_group_id": nsgID,
				"public_subnet_name":                       publicSubnet,
				"public_subnet_network_security_group_id":  nsgID,
				"no_public_ip":                             true,
			},
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	workspaceID := terraform.Output(t, terraformOptions, "workspace_id")
	assert.NotEmpty(t, workspaceID)
}

// TestIntegrationIdempotency verifies that apply is idempotent
func TestIntegrationIdempotency(t *testing.T) {
	skipIfNotIntegration(t)
	t.Parallel()

	uniqueID := random.UniqueId()
	resourceGroupName := fmt.Sprintf("rg-dbw-idem-test-%s", uniqueID)
	workspaceName := fmt.Sprintf("dbw-idem-test-%s", uniqueID)
	location := "westeurope"

	subscriptionID := os.Getenv("ARM_SUBSCRIPTION_ID")
	require.NotEmpty(t, subscriptionID)

	// Create resource group using Terraform
	rgTerraformOptions := createResourceGroupTerraformOptions(t, resourceGroupName, location)
	defer terraform.Destroy(t, rgTerraformOptions)
	terraform.InitAndApply(t, rgTerraformOptions)

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"name":                workspaceName,
			"resource_group_name": resourceGroupName,
			"location":            location,
			"sku":                 "premium",
			"access_connector": map[string]interface{}{
				"create": false,
			},
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, terraformOptions)

	// First apply
	terraform.InitAndApply(t, terraformOptions)

	// Second apply should show no changes
	planOutput := terraform.Plan(t, terraformOptions)
	assert.Contains(t, planOutput, "No changes", "Second apply should have no changes")
}

// createResourceGroupTerraformOptions creates a temporary Terraform config for resource group management
func createResourceGroupTerraformOptions(t *testing.T, resourceGroupName, location string) *terraform.Options {
	// Create a temporary directory with minimal Terraform config
	tmpDir := t.TempDir()

	// Write minimal Terraform configuration for resource group
	tfConfig := fmt.Sprintf(`
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  use_cli = true
}

resource "azurerm_resource_group" "test" {
  name     = "%s"
  location = "%s"

  tags = {
    Purpose = "integration-test"
    ManagedBy = "terratest"
  }
}
`, resourceGroupName, location)

	err := os.WriteFile(fmt.Sprintf("%s/main.tf", tmpDir), []byte(tfConfig), 0644)
	require.NoError(t, err)

	return &terraform.Options{
		TerraformDir: tmpDir,
		NoColor:      true,
	}
}
