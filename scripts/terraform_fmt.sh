# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

find . -type f -name "*.tf" -not -path '*/.terraform/*' -exec terraform fmt -write {} \;
