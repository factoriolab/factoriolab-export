data:extend(
  {
    {
      type = "bool-setting",
      name = "factoriolab-export-disable",
      order = "a",
      setting_type = "runtime-per-user",
      default_value = false
    },
    {
      type = "bool-setting",
      name = "factoriolab-export-pretty-json",
      order = "b",
      setting_type = "runtime-per-user",
      default_value = false
    },
    {
      type = "int-setting",
      name = "factoriolab-export-sprite-width",
      order = "c",
      setting_type = "runtime-per-user",
      default_value = 32,
      allowed_values = {32, 64, 128, 256}
    }
  }
)
