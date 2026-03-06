Function navigateUP(key, press, currentValue)
  nextPath = [m.navDirections.key[0], m.navDirections.key[1] - 1]
  navController(key, press, currentValue, nextPath)
End Function