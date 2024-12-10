# FortiGate Get Image in GCP - terraform module

This module helps you find the correct image based on the following search criteria:

- firmware version (var.ver - eg. "7.4.1" or shortened: "7.4" which returns newest image from 7.4 branch)
- licensing (var.lic - defaults to payg, allowed values: "payg", "byol")
- architecture (var.arch - defaults to x64, allowed values: "arm", "x64")
- family name (var.family)

If multiple images are matching, the result will point to the latest one.

### Outputs

- self_link - URI of the image
- image - object with all image attributes
