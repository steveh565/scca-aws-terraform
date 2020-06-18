
# Render VM Onboard script (for debugging purposes)
resource "local_file" "ScScADC-F5VM_F5-vm_onboard_file" {
  content     = data.template_file.ScScADC-F5VM_F5-vm_onboard.rendered
  filename    = "${path.module}/files/ScScADC-F5VM_F5-vm_onboard.sh"
}

# Render AS3 TS declaration
resource "local_file" "ScScADC-F5VM01_F5-as3_ts_json_file" {
  content     = data.template_file.ScScADC-F5VM01_F5-as3_ts_json.rendered
  filename    = "${path.module}/files/ScScADC-F5VM01_F5-as3_ts.json"
}

# Render TS declaration
resource "local_file" "ScScADC-F5VM01_F5-ts_json_file" {
  content     = data.template_file.ScScADC-F5VM01_F5-ts_json.rendered
  filename    = "${path.module}/files/ScScADC-F5VM01_F5-ts.json"
}

# Render DO declaration
resource "local_file" "ScScADC-F5VM02_F5-do_json_file" {
  content     = data.template_file.ScScADC-F5VM02_F5-do_json.rendered
  filename    = "${path.module}/files/ScScADC-F5VM02_F5-do.json"
}

# Render DO declaration
resource "local_file" "ScScADC-F5VM01_F5-do_json_file" {
  content     = data.template_file.ScScADC-F5VM01_F5-do_json.rendered
  filename    = "${path.module}/files/ScScADC-F5VM01_F5-do.json"
}
