# Copyright IBM Corp. 2021, 2023
# SPDX-License-Identifier: MPL-2.0

find . -type f -name "*.tf" -not -path '*/.terraform/*' -exec terraform fmt -write {} \;
