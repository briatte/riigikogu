# party colors

colors = c(
  "K"  = "#01665E", # dark green/teal
  "SDE" = "#E41A1C", # red
  "EER" = "#4DAF4A", # green
  "EV"  = "#80B1D3", # light blue
  "ERL" = "#377EB8",  # blue
  "EKRE" = "#377EB8", # blue; no intersection with ERL
  "RE" = "#FFFF33", # yellow
  "IRL" = "#053061" # dark blue
)

groups = c(
  "K"  = "Eesti Keskerakond",
  "SDE" = "Sotsiaaldemokraatlik Erakond",
  "EER" = "Erakonna Eestimaa Rohelised",
  "EV"  = "Eesti Vabaerakond",
  "ERL" = "Eesti Rahvuslik Liikumine",
  "EKRE" = "Eesti Konservatiivne Rahvaerakond",
  "RE" = "Eesti Reformierakond",
  "IRL" = "Erakond Isamaa ja Res Publica Liit"
)
# ParlGov Left/Right scores

scores = c(
  "K"  = 4,
  "SDE" = 4.2,
  "EER" = 5.6,
  "EV"  = 7.4,
  "ERL" = 7.4,
  "EKRE" = 7.4,
  "RE" = 7.9,
  "IRL" = 8.5
)

stopifnot(names(colors) == names(groups))
stopifnot(names(colors) == names(scores))
