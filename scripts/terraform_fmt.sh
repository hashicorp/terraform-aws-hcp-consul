find . -type f -name "*.tf" -not -path '*/.terraform/*' -exec terraform fmt -write {} \;
