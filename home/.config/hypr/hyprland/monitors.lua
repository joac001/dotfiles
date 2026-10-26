-- Fixed desk layout, matched by monitor description (connector names change between boots).
-- Rules for monitors that aren't connected are ignored, so this is harmless on other machines.
hl.monitor({ output = "desc:LG Electronics E2042 SerialNumber",           mode = "preferred", position = "0x0",    scale = 1 })
hl.monitor({ output = "desc:LG Electronics LG ULTRAGEAR 502NTPC28104",    mode = "highrr",    position = "1600x0", scale = 1 })
hl.monitor({ output = "desc:LG Electronics LG ULTRAGEAR 502NTCZ28539",    mode = "highrr",    position = "3520x0", scale = 1 })
