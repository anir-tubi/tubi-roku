Function componentTest_InfoPanel_movieMode(screen, runTests)
  ' Info Panel children for 'movie' mode
  '   m.Title
  '   m.TwoLineInfo
  '   m.Description
  '   m.DirectorGroup
  '   m.StarringGroup
  data = [
  {
    "mode": "movie"
    "title": "Test Title"
    "releaseDate": "2018"
    "length": 4000
    "hasCC": true
    "rating": "TV-MA"
    "genres": ["Horror", "Comedy", "Drama"]
    "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Satis est ad hoc responsum. Hoc tu nunc in illo probas. Occultum facinus esse potuerit, gaudebit; Tamen a proposito, inquam, aberramus. Quae quo sunt excelsiores, eo dant clariora indicia naturae. Quis est tam dissimile homini. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Satis est ad hoc responsum. Hoc tu nunc in illo probas. Occultum facinus esse potuerit, gaudebit; Tamen a proposito, inquam, aberramus. Quae quo sunt excelsiores, eo dant clariora indicia naturae. Quis est tam dissimile homini."
    "directors": ["Martin Scorsese", "Ridley Scott", "John Woo", "Christopher Nolan"]
    "starring": ["Jack Nicholson", "Marlon Brando", "Robert De Niro", "Al Pacino"]
    "translation": [100,0]
    "width": 875
  }
  {
    "calculateHeight": true
  }
  ]
  runTests("InfoPanel", data, ["descriptionSelected"])
End Function


Function componentTest_InfoPanel_seriesMode(screen, runTests)
  ' Info Panel children for 'series' mode
  '   m.Title
  '   m.Episode
  '   m.TwoLineInfo
  '   m.Description
  '   m.DirectorGroup
  '   m.StarringGroup
  data = [
  {
    "mode": "series"
    "title": "Test Title"
    "episodeTitle": "S01:E01 Test Episode Title"
    "releaseDate": "2018"
    "length": 4000
    "hasCC": true
    "rating": "TV-MA"
    "genres": ["Horror", "Comedy", "Drama"]
    "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Satis est ad hoc responsum. Hoc tu nunc in illo probas. Occultum facinus esse potuerit, gaudebit; Tamen a proposito, inquam, aberramus. Quae quo sunt excelsiores, eo dant clariora indicia naturae. Quis est tam dissimile homini. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Satis est ad hoc responsum. Hoc tu nunc in illo probas. Occultum facinus esse potuerit, gaudebit; Tamen a proposito, inquam, aberramus. Quae quo sunt excelsiores, eo dant clariora indicia naturae. Quis est tam dissimile homini."
    "directors": ["Martin Scorsese", "Ridley Scott", "John Woo", "Christopher Nolan"]
    "starring": ["Jack Nicholson", "Marlon Brando", "Robert De Niro", "Al Pacino"]
    "translation": [100,0]
    "width": 875
  }
  {
    "calculateHeight": true
  }
  ]
  runTests("InfoPanel", data, ["descriptionSelected"])
End Function


Function componentTest_InfoPanel_categoryMode(screen, runTests)
  ' Info Panel children for 'category' mode
  '   m.Title
  '   m.CategoryDetails
  '   m.Description
  data = [
  {
    "id":            "InfoPanel"
    "maxHeight":     325
    "maxTitleLines": 2
    "visible":       true
  }
  { "mode": "category" }
  { "categoryContentCount": 75 }
  { "title": "Test Title" }
  { "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Satis est ad hoc responsum. Hoc tu nunc in illo probas. Occultum facinus esse potuerit, gaudebit; Tamen a proposito, inquam, aberramus. Quae quo sunt excelsiores, eo dant clariora indicia naturae. Quis est tam dissimile homini. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Satis est ad hoc responsum. Hoc tu nunc in illo probas. Occultum facinus esse potuerit, gaudebit; Tamen a proposito, inquam, aberramus. Quae quo sunt excelsiores, eo dant clariora indicia naturae. Quis est tam dissimile homini." }
  {
    "calculateHeight": true
  }
  ]
  runTests("InfoPanel", data, ["descriptionSelected"])
End Function


Function componentTest_InfoPanel_categoryScreen_itemMode(screen, runTests)
  ' Force fields to be set in the exact order as CategoryScreen
  data = [
  {
    "translation": [85,163]
    "maxHeight": 325
    "maxTitleLines": 2
    "width": 875
  }
  { "mode": "item" }
  { "title": "Title" }
  { "description": "Description Description Description Description Description Description Description Description Description Description" }
  { "releaseDate": "2018" }
  { "length": 5500 }
  { "rating": "TV-MA" }
  { "genres": ["Comedy", "Horror"] }
  { "hasCC": true }
  { "calculateHeight": true }
  ]
  runTests("InfoPanel", data, ["descriptionSelected"])
End Function
