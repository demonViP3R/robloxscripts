getgenv().fov = 300
getgenv().wallcheck = true -- Switch this to true if you don't want the silent aim to target people behind cover!
loadstring(
	game:HttpGet(
		"https://raw.githubusercontent.com/sneekygoober/War-Tycoon-Silent-Aim-Script/refs/heads/main/main.luau"
	)
)()
