#
#Evernote = require('evernote').Evernote
#{Thrift, NoteStoreClient, Client} = Evernote
#
#TOKEN = "S=s59:U=a0939c:E=155aa42d624:C=14e5291a6d0:P=185:A=noman169:V=2:B=cac5c895-a114-47d2-af84-131d1fad3067:H=76e0de03b61fc128e987610bb73f3ecf"
#
#client = new Client(
#    token:TOKEN
#    serviceHost:"app.yinxiang.com"
#)
#store = client.getNoteStore()
#filter = new Evernote.NoteFilter()
#filter.words = "tag:@*"
#
#spec = new Evernote.NotesMetadataResultSpec()
#spec.includeUpdateSequenceNum = true
#spec.includeTitle= true
#
#
#nBody = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
#nBody += "<!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\">"
#nBody += "<en-note>1312312313212131232</en-note>"
#
#ourNote = new Evernote.Note()
#ourNote.title = "234xxx"
#ourNote.content = nBody
#
#
#
#store.findNotesMetadata(
#    filter, 0, 100, spec,
#    (err,li)->
#        console.log err
#        console.log li
#)
#
