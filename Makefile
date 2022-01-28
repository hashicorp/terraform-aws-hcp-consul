.DEFAULT_GOAL := generate_templates

generate_templates: hashicups_version module_version
	scripts/generate_ui_templates.sh

dummy_data: generate_templates
	scripts/dummy_data.sh

hashicups_version:
	scripts/hashicups_version.sh

toggle_dev:
	scripts/toggle_dev.sh

module_version:
	scripts/module_version.sh

clean:
	rm -rf examples/existing-vpc/output.json
