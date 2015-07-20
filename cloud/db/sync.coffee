require "cloud/db/oauth"
trim = require("underscore.string/trim")
evernote2html = require "cloud/db/evernote2html"
brief2markdown = require "cloud/db/brief2markdown"
require 'cloud/db/post_inbox'
require "cloud/db/post"
require "enml-js"
DB = require "cloud/_db"


Evernote = require('evernote').Evernote
{Thrift, NoteStoreClient, Client} = Evernote

_oauth_get = (params, callback)->
    DB.Oauth.$.get(params.id, {
        success: (oauth) ->
            client = new Client(
                token:oauth.get('token')
                serviceHost:DB.Oauth._host_by_kind(oauth.get('kind'))
            )
            store = client.getNoteStore()
            callback oauth, store
    })


DB class EvernoteSyncCount
    constructor : (
        @oauth_id
        @count
        @pre_count
    ) ->
        super

    @rm : (id)->
        DB.EvernoteSyncCount.$.rm {oauth_id:id}

DB class EvernoteSync
    constructor : (
        @oauth_id
        @update_count
    ) ->
        super
    


    @new: (params) ->
        EvernoteSync.$.get_or_create({
            oauth_id:params.oauth_id
        }, {
            success:(o) ->
                o.set(
                    update_count : params.update_count
                )
                o.save()
        })

    @sync: (params, options) ->
        options.success ''
        _oauth_get(params, (oauth, store)->
            _sync = (evernote_sync) ->
                update_count = 0
                if evernote_sync
                    update_count = evernote_sync.get('update_count')
                

                EvernoteSyncCount.$.get_or_create(
                    {
                        oauth_id
                    }
                    success:(_c)->
                        _c.set "count",0
                        _c.save success:(counter)->
                            to_update_count = 0


                            _fetch = (note)->
                                ++ to_update_count
                                guid = note.guid
                                store.getNote(guid, true, true, false, false, (err, full_note) ->
                                    if err
                                        console.log err
                                        return
                                    store.getNoteTagNames(guid, (err, taglist) ->

                                        tag_list = []
                                        site_tag_list = []
                                        for each_tag in taglist
                                            if each_tag.charAt(0) != '@'
                                                tag_list.push each_tag
                                            else
                                                each_tag = trim each_tag.slice(1).toLowerCase()
                                                if each_tag != "blog"
                                                    site_tag_list.push each_tag

                                        evernote2html full_note, (html)->
                                            [brief,html] = brief2markdown(html)
                                            owner = oauth.get 'user'
                                            EvernotePost.new(
                                                guid
                                                (id, success)->
                                                    data = {
                                                        title: full_note.title
                                                        html
                                                        owner
                                                        tag_list
                                                        id
                                                    }
                                                    if brief
                                                        data.brief = brief
                                                    DB.PostHtml.new(
                                                        data
                                                        {
                                                        success:(post)->
                                                            DB.PostInbox._submit_by_evernote(post, site_tag_list)
                                                            success post
                                                            -- to_update_count
                                                            if to_update_count > 0
                                                                counter.increment 'count'
                                                                counter.save()
                                                            else
                                                                the_end()
                                                        }
                                                    )
                                            )
                                    )
                                )
                            updateCount = update_count
                            the_end = ->
                                EvernoteSyncCount.rm oauth_id
                                EvernoteSync.new {
                                    oauth_id
                                    update_count: updateCount
                                }
                            
                            filter = new Evernote.NoteFilter()
                            filter.words = """tag:@*"""
                            filter.order = Evernote.NoteSortOrder.UPDATE_SEQUENCE_NUMBER
                            spec = new Evernote.NotesMetadataResultSpec()
                            spec.includeUpdateSequenceNum = true
                            spec.includeUpdated = true
                            #spec.includeDeleted = true
                            #spec.includeTitle= true

                            _ = (offset)->
                                if offset > 0
                                    limit = 3
                                else
                                    limit = 100
                                store.findNotesMetadata(
                                    filter, offset, limit, spec
                                    (err, li) ->
                                        if err or not li
                                            console.log err
                                            return

                                        updateCount = li.updateCount
                                        if not li.notes.length
                                            the_end()
                                            return
    
                                        for note in li.notes
                                            if note.updateSequenceNum <= update_count
                                                break
                                            _fetch note
                                    
                                )
                            _ 0
                    )

            query = EvernoteSync.$
            oauth_id = params.id
            query.equalTo {oauth_id}
            query.first(
                success: (evernote_sync) ->
                    _sync(evernote_sync)
                error:(err) ->
                    if err.code == 101
                        _sync()
                    else
                        console.log err
            )
        )
            
     @count: (params, options) ->
        q = EvernoteSyncCount.$
        q.equalTo {
            oauth_id:params.id
        }
        q.first({
            success:(counter) ->
                if counter
                    count = counter.get('count')
                    pre_count = counter.get('pre_count')

                    if count < 0 or (pre_count == count and ((new Date())-counter.updatedAt)/1000 > 30)
                        EvernoteSyncCount.rm params.id
                        count = -1
                    else if count != pre_count
                        counter.set 'pre_count', count
                        counter.save()
                else
                    count = -1
                options.success count
        })




DB class EvernotePost
    constructor : (
        @guid
        @post
    ) ->
        super

    @new: (guid, post_new) ->
        EvernotePost.$.get_or_create({
            guid
        },{
        #    create:(o)->
        #        console.log "new"
            success:(o)->
                _post = o.get('post')

                if _post
                    post_id = _post.id
                else
                    post_id = 0
                post_new post_id, (post)->
                    if post_id != post.id
                        o.set {post}
                        o.save()
        })


DB.Post.EVENT.on "rm", (post) ->
    EvernotePost.$.equalTo({ post }).destroyAll()
