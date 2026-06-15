function onload()

  colStr = self.getDescription()

  tableCols = Player.getAvailableColors()
  table.insert(tableCols,'Grey')
  player = Player[colStr]
  handPars = player.getHandTransform()
  Pos = handPars.position+handPars.forward:scale(4)
  Pos[2] = 1.05
  Rot = handPars.rotation+Vector(0,90,0)

  self.setPosition(Pos)
  self.setRotation(Rot)
  self.setInvisibleTo(tableCols)
  self.setColorTint{0,0,0,1}
  self.setLock(true)
  self.setScale({1,1,2.2})
  self.interactable = false

end