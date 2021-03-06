Feature: Kill a content item in the (dusty) archive

  Background: Setup data
    Given "desks"
    """
    [{"name": "Sports", "content_expiry": 60, "members": [{"user": "#CONTEXT_USER_ID#"}]}]
    """
    And "validators"
    """
    [{"schema": {}, "type": "text", "act": "publish", "_id": "publish_text"},
     {"schema": {}, "type": "text", "act": "correct", "_id": "correct_text"},
     {"schema": {}, "type": "text", "act": "kill", "_id": "kill_text"}]
    """
    When we post to "/products" with success
      """
      {
        "name":"prod-1","codes":"abc,xyz"
      }
      """
    And we post to "/subscribers" with "digital" and success
    """
    {
      "name":"Channel 1", "media_type":"media", "subscriber_type": "digital", "sequence_num_settings":{"min" : 1, "max" : 10}, "email": "test@test.com",
      "products": ["#products._id#"],
      "destinations":[{"name":"Test","format": "nitf", "delivery_type":"email","config":{"recipients":"test@test.com"}}]
    }
    """
    And we post to "/subscribers" with "wire" and success
    """
    {
      "name":"Channel 2", "media_type":"media", "subscriber_type": "wire", "sequence_num_settings":{"min" : 1, "max" : 10}, "email": "test@test.com",
      "products": ["#products._id#"],
      "destinations":[{"name":"Test","format": "nitf", "delivery_type":"email","config":{"recipients":"test@test.com"}}]
    }
    """
    When we post to "content_templates"
    """
    {"template_name": "kill", "template_type": "kill",
     "data": {"body_html": "<p>Story killed due to court case. Please remove the story from your archive.<\/p>",
              "type": "text", "abstract": "This article has been removed", "headline": "Kill\/Takedown notice ~~~ Kill\/Takedown notice",
              "urgency": 1, "priority": 1,  "anpa_take_key": "KILL\/TAKEDOWN"}
    }
    """

  @auth @notification
  Scenario: Kill a Text Article in the Dusty Archive
    When we post to "/archive" with success
    """
    [{"guid": "123", "type": "text", "state": "fetched", "slugline": "archived",
      "headline": "headline", "anpa_category" : [{"qcode" : "e", "name" : "Entertainment"}],
      "task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#", "user": "#CONTEXT_USER_ID#"},
      "subject":[{"qcode": "17004000", "name": "Statistics"}], "targeted_for": [{"name": "Digital", "allow": false}],
      "dateline" : {
        "located" : {
            "state_code" : "NSW",
            "city" : "Sydney",
            "tz" : "Australia/Sydney",
            "country_code" : "AU",
            "dateline" : "city",
            "alt_name" : "",
            "state" : "New South Wales",
            "city_code" : "Sydney",
            "country" : "Australia"
        },
        "source" : "AAP",
        "date" : "2016-04-13T04:29:14",
        "text" : "SYDNEY April 13 AAP -"
      },
      "body_html": "Test Document body"}]
    """
    Then we get OK response
    When we publish "#archive._id#" with "publish" type and "published" state
    Then we get OK response
    When we get "/published"
    Then we get list with 1 items
    """
    {"_items" : [{"_id": "123", "state": "published", "type": "text", "_current_version": 2}]}
    """
    When we enqueue published
    And we get "/publish_queue"
    Then we get list with 1 items
    When we transmit items
    And run import legal publish queue
    And we expire items
    """
    ["123"]
    """
    And we get "/published"
    Then we get list with 0 items
    When we enqueue published
    And we get "/publish_queue"
    Then we get list with 0 items
    When we get "/archived"
    Then we get list with 1 items
    """
    {"_items" : [{"item_id": "123", "state": "published", "type": "text", "_current_version": 2}]}
    """
    When run import legal publish queue
    And we get "/legal_publish_queue"
    Then we get list with 1 items
    When we patch "/archived/123:2"
    """
    {"body_html": "Killed body."}
    """
    Then we get OK response
    And we get 1 emails
    When we get "/published"
    Then we get list with 1 items
    """
    {"_items" : [{"_id": "123", "state": "killed", "type": "text", "_current_version": 3, "queue_state": "queued"}]}
    """
    When we transmit items
    And run import legal publish queue
    And we get "/legal_publish_queue"
    Then we get list with 2 items
    """
    {"_items" : [
        {"item_id": "123", "content_type": "text", "item_version": 2, "publishing_action": "published"},
        {"item_id": "123", "content_type": "text", "item_version": 3, "publishing_action": "killed"}
     ]}
    """
    When we get "/archive/123"
    Then we get OK response
    And we get text "Please kill story slugged archived" in response field "body_html"
    And we get text "Killed body" in response field "body_html"
    When we get "/archived/123:2"
    Then we get error 404
    When we get "/archived"
    Then we get list with 0 items
    When we get "/legal_archive/123"
    Then we get existing resource
    """
    {"_id": "123", "type": "text", "_current_version": 3, "state": "killed", "pubstatus": "canceled", "operation": "kill"}
    """
    When we get "/legal_archive/123?version=all"
    Then we get list with 3 items
    When we expire items
    """
    ["123"]
    """
    And we get "/published"
    Then we get list with 0 items
    When we get "/archive"
    Then we get list with 0 items

  @auth @notification
  Scenario: Kill a Text Article that exists only in Archived
    Given "archived" with objectid
    """
    [{
      "_id": "56aad5a61d41c8aa98ddd015", "guid": "123", "item_id": "123", "_current_version": "1", "type": "text", "abstract": "test", "state": "fetched", "slugline": "slugline",
      "headline": "headline", "anpa_category" : [{"qcode" : "e", "name" : "Entertainment"}],
      "flags" : {"marked_archived_only": true},
      "subject":[{"qcode": "17004000", "name": "Statistics"}],
      "body_html": "Test Document body"
    }]
    """
    When we patch "/archived/56aad5a61d41c8aa98ddd015"
    """
    {}
    """
    When we get "/archived"
    Then we get list with 0 items
    And we get 1 emails

  @auth @notification
  Scenario: Kill a Text Article also kills the Digital Story in the Dusty Archive
    When we post to "/archive" with success
    """
    [{"guid": "123", "type": "text", "abstract": "test", "state": "fetched", "slugline": "slugline",
      "headline": "headline", "anpa_category" : [{"qcode" : "e", "name" : "Entertainment"}],
      "task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#", "user": "#CONTEXT_USER_ID#"},
      "subject":[{"qcode": "17004000", "name": "Statistics"}],
      "body_html": "Test Document body"}]
    """
    Then we get OK response
    When we publish "#archive._id#" with "publish" type and "published" state
    Then we get OK response
    When we get "/published"
    Then we get list with 2 items
    """
    {"_items" : [
      {"sequence": 1,
       "package_type": "takes",
       "state": "published",
       "type": "composite",
       "_current_version": 2
      },
      {"state": "published",
       "type": "text",
       "_current_version": 2}
      ]
    }
    """
    When we enqueue published
    When we get "/publish_queue"
    Then we get list with 2 items
    When we transmit items
    And run import legal publish queue
    And we expire items
    """
    ["123", "#archive.123.take_package#"]
    """
    And we get "/published"
    Then we get list with 0 items
    When we get "/publish_queue"
    Then we get list with 0 items
    When we get "/archived"
    Then we get list with 2 items
    """
    {"_items" : [
      {"package_type": "takes", "item_id": "#archive.123.take_package#", "state": "published", "type": "composite", "_current_version": 2},
      {"item_id": "123", "state": "published", "type": "text", "_current_version": 2}
      ]
    }
    """
    When we get "/legal_publish_queue"
    Then we get list with 2 items
    When we patch "/archived/123:2"
    """
    {"body_html": "Killed body"}
    """
    Then we get OK response
    And we get 2 emails
    When we get "/published"
    Then we get list with 2 items
    When we get "/publish_queue"
    Then we get list with 2 items
    When we get "/archive/123"
    Then we get OK response
    And we get text "Please kill story slugged slugline" in response field "body_html"
    And we get text "Killed body" in response field "body_html"
    When we get "/archive/#archive.123.take_package#"
    Then we get OK response
    And we get text "Please kill story slugged slugline" in response field "body_html"
    And we get text "Killed body" in response field "body_html"
    When we get "/archived"
    Then we get list with 0 items
    When we transmit items
    And run import legal publish queue
    When we get "/legal_archive/123"
    Then we get existing resource
    """
    {"_id": "123", "type": "text", "_current_version": 3, "state": "killed", "pubstatus": "canceled", "operation": "kill"}
    """
    When we get "/legal_archive/123?version=all"
    Then we get list with 3 items
    When we get "/legal_archive/#archive.123.take_package#"
    Then we get existing resource
    """
    {"_id": "#archive.123.take_package#", "type": "composite", "_current_version": 3, "state": "killed", "pubstatus": "canceled", "operation": "kill"}
    """
    When we get "/legal_archive/#archive.123.take_package#?version=all"
    Then we get list with 2 items
    When we get "/legal_publish_queue"
    Then we get list with 4 items
    When we expire items
    """
    ["123", "#archive.123.take_package#"]
    """
    And we get "/published"
    Then we get list with 0 items

  @auth @notification
  Scenario: Killing Take in Dusty Archive will kill other takes including the Digital Story
    When we post to "/archive" with success
    """
    [{"guid": "123", "type": "text", "abstract": "test", "state": "fetched", "slugline": "slugline",
      "headline": "headline", "anpa_category" : [{"qcode" : "e", "name" : "Entertainment"}],
      "task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#", "user": "#CONTEXT_USER_ID#"},
      "subject":[{"qcode": "17004000", "name": "Statistics"}], "body_html": "Test Document body"}]
    """
    Then we get OK response
    When we post to "archive/123/link"
    """
    [{"desk": "#desks._id#"}]
    """
    Then we get next take as "take1"
    """
    {"_id": "#take1#"}
    """
    When we patch "/archive/#take1#"
    """
    {"abstract": "Take 1", "headline": "Take 1", "body_html": "Take 1"}
    """
    And we post to "archive/#take1#/link"
    """
    [{"desk": "#desks._id#"}]
    """
    Then we get next take as "take2"
    """
    {"_id": "#take2#"}
    """
    When we patch "/archive/#take2#"
    """
    {"abstract": "Take 2", "headline": "Take 2", "body_html": "Take 2"}
    """
    When we publish "123" with "publish" type and "published" state
    Then we get OK response
    When we publish "123" with "correct" type and "corrected" state
    """
    {"body_html": "Corrected", "slugline": "corrected", "headline": "corrected"}
    """
    Then we get OK response
    When we publish "#take1#" with "publish" type and "published" state
    Then we get OK response
    When we publish "#take2#" with "publish" type and "published" state
    Then we get OK response
    When we get "/published"
    Then we get list with 8 items
    When we enqueue published
    When we get "/publish_queue"
    Then we get list with 8 items
    When we transmit items
    And run import legal publish queue
    And we expire items
    """
    ["123", "#take1#", "#take2#", "#archive.123.take_package#"]
    """
    And we get "/published"
    Then we get list with 0 items
    When we enqueue published
    When we get "/publish_queue"
    Then we get list with 0 items
    When we get "/archived"
    Then we get list with 8 items
    When we enqueue published
    When we get "/legal_publish_queue"
    Then we get list with 8 items
    When we patch "/archived/123:2"
    """
    {}
    """
    Then we get OK response
    And we get 4 emails
    When we get "/published"
    Then we get list with 4 items
    When we get "/publish_queue"
    Then we get list with 4 items
    When we get "/archived"
    Then we get list with 0 items
    When we transmit items
    And run import legal publish queue
    When we get "/legal_archive/123"
    Then we get existing resource
    """
    {"_id": "123", "type": "text", "_current_version": 4, "state": "killed", "pubstatus": "canceled", "operation": "kill"}
    """
    When we get "/legal_archive/123?version=all"
    Then we get list with 4 items
    When we get "/legal_archive/#archive.123.take_package#"
    Then we get existing resource
    """
    {"_id": "#archive.123.take_package#", "type": "composite", "_current_version": 7, "state": "killed", "pubstatus": "canceled", "operation": "kill"}
    """
    When we get "/legal_archive/#archive.123.take_package#?version=all"
    Then we get list with 7 items
    When we get "/legal_archive/#take1#"
    Then we get existing resource
    """
    {"_id": "#take1#", "type": "text", "_current_version": 4, "state": "killed", "pubstatus": "canceled", "operation": "kill"}
    """
    When we get "/legal_archive/#take1#?version=all"
    Then we get list with 4 items
    When we get "/legal_archive/#take2#"
    Then we get existing resource
    """
    {"_id": "#take2#", "type": "text", "_current_version": 4, "state": "killed", "pubstatus": "canceled", "operation": "kill"}
    """
    When we get "/legal_archive/#take2#?version=all"
    Then we get list with 4 items
    When we expire items
    """
    ["123", "#take1#", "#take2#", "#archive.123.take_package#"]
    """
    And we get "/published"
    Then we get list with 0 items

  @auth
  Scenario: Killing an article other than Text isn't allowed
    Given "archived"
    """
    [{"item_id": "123", "guid": "123", "type": "preformatted", "headline": "test", "slugline": "slugline",
      "headline": "headline", "anpa_category" : [{"qcode" : "e", "name" : "Entertainment"}], "state": "published",
      "task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#", "user": "#CONTEXT_USER_ID#"},
      "subject":[{"qcode": "17004000", "name": "Statistics"}], "body_html": "Test Document body", "_current_version": 2}]
    """
    When we delete "/archived/#archived._id#"
    Then we get error 400
    """
    {"_message": "Only Text articles are allowed to Kill in Archived repo"}
    """

  @auth
  Scenario: Killing a Broadcast isn't allowed
    Given "archived"
    """
    [{"item_id": "123", "guid": "123", "type": "text", "headline": "test", "slugline": "slugline",
      "genre": [{"name": "Broadcast Script", "qcode": "Broadcast Script"}], "headline": "headline",
      "anpa_category" : [{"qcode" : "e", "name" : "Entertainment"}], "state": "published",
      "task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#", "user": "#CONTEXT_USER_ID#"},
      "subject":[{"qcode": "17004000", "name": "Statistics"}], "body_html": "Test Document body", "_current_version": 2}]
    """
    When we delete "/archived/#archived._id#"
    Then we get error 400
    """
    {"_message": "Killing of Broadcast Items isn't allowed in Archived repo"}
    """

  @auth
  Scenario: Killing an article isn't allowed if it's available in production
    Given "archive"
    """
    [{"guid": "123", "type": "text", "headline": "test", "slugline": "slugline",
      "headline": "headline", "anpa_category" : [{"qcode" : "e", "name" : "Entertainment"}], "state": "published",
      "task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#", "user": "#CONTEXT_USER_ID#"},
      "subject":[{"qcode": "17004000", "name": "Statistics"}], "body_html": "Test Document body", "_current_version": 2}]
    """
    And "archived"
    """
    [{"item_id": "123", "guid": "123", "type": "text", "headline": "test", "slugline": "slugline",
      "headline": "headline", "anpa_category" : [{"qcode" : "e", "name" : "Entertainment"}], "state": "published",
      "task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#", "user": "#CONTEXT_USER_ID#"},
      "subject":[{"qcode": "17004000", "name": "Statistics"}], "body_html": "Test Document body", "_current_version": 2}]
    """
    When we delete "/archived/#archived._id#"
    Then we get error 400
    """
    {"_message": "Can't Kill as article is still available in production"}
    """

  @auth
  Scenario: Killing an article isn't allowed if it's part of a package
    Given "archived"
    """
    [{"item_id": "123", "guid": "123", "type": "text", "headline": "test", "slugline": "slugline",
      "headline": "headline", "anpa_category" : [{"qcode" : "e", "name" : "Entertainment"}], "state": "published",
      "task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#", "user": "#CONTEXT_USER_ID#"},
      "linked_in_packages": [{"package" : "234"}],
      "subject":[{"qcode": "17004000", "name": "Statistics"}], "body_html": "Test Document body", "_current_version": 2},
     {"groups": [{"id": "root", "refs": [{"idRef": "main"}]},
                {"id": "main", "refs": [{"headline": "headline", "slugline": "slugline", "residRef": "123"}]}
               ],
      "item_id": "234", "guid": "234", "type": "composite", "_current_version": 2, "state": "published",
      "task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#", "user": "#CONTEXT_USER_ID#"}}
    ]
    """
    When we delete "/archived/123:2"
    Then we get error 400
    """
    {"_message": "Can't kill as article is part of a Package"}
    """

  @auth
  Scenario: Killing an article isn't allowed if it's associated digital story is part of a package
    Given "archived"
    """
    [
     {"item_id": "123", "guid": "123", "type": "text", "headline": "test", "slugline": "slugline",
      "headline": "headline", "anpa_category" : [{"qcode" : "e", "name" : "Entertainment"}], "state": "published",
      "task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#", "user": "#CONTEXT_USER_ID#"},
      "linked_in_packages": [{"package_type" : "takes", "package" : "234"}],
      "subject":[{"qcode": "17004000", "name": "Statistics"}], "body_html": "Test Document body", "_current_version": 2},
     {"groups": [{"id": "root", "refs": [{"idRef": "main"}]},
                {"id": "main", "refs": [{"headline": "headline", "slugline": "slugline", "residRef": "123", "sequence": 1}]}
               ],
      "linked_in_packages": [{"package" : "345"}],
      "item_id": "234", "guid": "234", "type": "composite", "package_type": "takes", "sequence": 1, "_current_version": 2,
      "state": "published", "task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#", "user": "#CONTEXT_USER_ID#"}},
     {"groups": [{"id": "root", "refs": [{"idRef": "main"}]},
                {"id": "main", "refs": [{"headline": "headline", "slugline": "slugline", "residRef": "234"}]}
               ],
      "item_id": "345", "guid": "345", "type": "composite", "_current_version": 2, "state": "published",
      "task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#", "user": "#CONTEXT_USER_ID#"}}
    ]
    """
    When we delete "/archived/123:2"
    Then we get error 400
    """
    {"_message": "Can't kill as Digital Story is part of a Package"}
    """

  @auth
  Scenario: Killing an article isn't allowed if any of the takes are available in production
    Given "archive"
    """
    [
     {"item_id": "234", "guid": "234", "type": "text", "headline": "Take-2", "slugline": "Take-2",
      "headline": "headline", "anpa_category" : [{"qcode" : "e", "name" : "Entertainment"}], "state": "published",
      "task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#", "user": "#CONTEXT_USER_ID#"},
      "linked_in_packages": [{"package_type" : "takes", "package" : "345"}],
      "subject":[{"qcode": "17004000", "name": "Statistics"}], "body_html": "Test Document body", "_current_version": 2}
    ]
    """
    And "archived"
    """
    [
     {"item_id": "123", "guid": "123", "type": "text", "headline": "Take-1", "slugline": "Take-1",
      "headline": "headline", "anpa_category" : [{"qcode" : "e", "name" : "Entertainment"}], "state": "published",
      "task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#", "user": "#CONTEXT_USER_ID#"},
      "linked_in_packages": [{"package_type" : "takes", "package" : "345"}],
      "subject":[{"qcode": "17004000", "name": "Statistics"}], "body_html": "Test Document body", "_current_version": 2},
     {"item_id": "234", "guid": "234", "type": "text", "headline": "Take-2", "slugline": "Take-2",
      "headline": "headline", "anpa_category" : [{"qcode" : "e", "name" : "Entertainment"}], "state": "published",
      "task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#", "user": "#CONTEXT_USER_ID#"},
      "linked_in_packages": [{"package_type" : "takes", "package" : "345"}],
      "subject":[{"qcode": "17004000", "name": "Statistics"}], "body_html": "Test Document body", "_current_version": 2},
     {"groups": [{"id": "root", "refs": [{"idRef": "main"}]},
                {"id": "main", "refs": [{"headline": "Take-1", "slugline": "Take-1", "residRef": "123", "sequence": 1, "is_published": true},
                                        {"headline": "Take-2", "slugline": "Take-2", "residRef": "234", "sequence": 2, "is_published": true}]}
               ],
      "item_id": "345", "guid": "345", "type": "composite", "package_type": "takes", "sequence": 2, "_current_version": 2,
      "state": "published", "task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#", "user": "#CONTEXT_USER_ID#"}}
    ]
    """
    When we delete "/archived/123:2"
    Then we get error 400
    """
    {"_message": "Can't Kill as Take(s) are still available in production"}
    """

  @auth
  Scenario: Killing an article isn't allowed if all the takes are not available in Archived repo
    Given "archived"
    """
    [
     {"item_id": "123", "guid": "123", "type": "text", "headline": "Take-1", "slugline": "Take-1",
      "headline": "headline", "anpa_category" : [{"qcode" : "e", "name" : "Entertainment"}], "state": "published",
      "task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#", "user": "#CONTEXT_USER_ID#"},
      "linked_in_packages": [{"package_type" : "takes", "package" : "345"}],
      "subject":[{"qcode": "17004000", "name": "Statistics"}], "body_html": "Test Document body", "_current_version": 2},
     {"groups": [{"id": "root", "refs": [{"idRef": "main"}]},
                {"id": "main", "refs": [{"headline": "Take-1", "slugline": "Take-1", "residRef": "123", "sequence": 1, "is_published": true},
                                        {"headline": "Take-2", "slugline": "Take-2", "residRef": "234", "sequence": 2, "is_published": true}]}
               ],
      "item_id": "345", "guid": "345", "type": "composite", "package_type": "takes", "sequence": 2, "_current_version": 2,
      "state": "published", "task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#", "user": "#CONTEXT_USER_ID#"}}
    ]
    """
    When we delete "/archived/123:2"
    Then we get error 400
    """
    {"_message": "One of Take(s) not found in Archived repo"}
    """

  @auth
  Scenario: Killing an article isn't allowed if any of the takes is part of a package
    Given "archived"
    """
    [
     {"item_id": "123", "guid": "123", "type": "text", "headline": "Take-1", "slugline": "Take-1",
      "headline": "headline", "anpa_category" : [{"qcode" : "e", "name" : "Entertainment"}], "state": "published",
      "task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#", "user": "#CONTEXT_USER_ID#"},
      "linked_in_packages": [{"package_type" : "takes", "package" : "345"}],
      "subject":[{"qcode": "17004000", "name": "Statistics"}], "body_html": "Test Document body", "_current_version": 2},
     {"item_id": "234", "guid": "234", "type": "text", "headline": "Take-2", "slugline": "Take-2",
      "headline": "headline", "anpa_category" : [{"qcode" : "e", "name" : "Entertainment"}], "state": "published",
      "task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#", "user": "#CONTEXT_USER_ID#"},
      "linked_in_packages": [{"package_type" : "takes", "package" : "345"}, {"package" : "456"}],
      "subject":[{"qcode": "17004000", "name": "Statistics"}], "body_html": "Test Document body", "_current_version": 2},
     {"groups": [{"id": "root", "refs": [{"idRef": "main"}]},
                {"id": "main", "refs": [{"headline": "Take-1", "slugline": "Take-1", "residRef": "123", "sequence": 1, "is_published": true},
                                        {"headline": "Take-2", "slugline": "Take-2", "residRef": "234", "sequence": 2, "is_published": true}]}
               ],
      "item_id": "345", "guid": "345", "type": "composite", "package_type": "takes", "sequence": 2, "_current_version": 2,
      "state": "published", "task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#", "user": "#CONTEXT_USER_ID#"}},
     {"groups": [{"id": "root", "refs": [{"idRef": "main"}]},
                {"id": "main", "refs": [{"headline": "headline", "slugline": "slugline", "residRef": "234"}]}
               ],
      "item_id": "456", "guid": "456", "type": "composite", "_current_version": 2, "state": "published",
      "task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#", "user": "#CONTEXT_USER_ID#"}}
    ]
    """
    When we delete "/archived/123:2"
    Then we get error 400
    """
    {"_message": "Can't kill as one of Take(s) is part of a Package"}
    """

  @auth
  Scenario: Killing an article isn't allowed if article is a Master Story for Broadcast(s)
    Given "archived"
    """
    [
     {"item_id": "123", "guid": "123", "type": "text", "headline": "Take-1", "slugline": "Take-1",
      "headline": "headline", "anpa_category" : [{"qcode" : "e", "name" : "Entertainment"}], "state": "published",
      "task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#", "user": "#CONTEXT_USER_ID#"},
      "subject":[{"qcode": "17004000", "name": "Statistics"}], "body_html": "Test Document body", "_current_version": 2},
     {"item_id": "234", "anpa_category" : [{"qcode" : "e", "name" : "Entertainment"}], "state": "published",
      "task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#", "user": "#CONTEXT_USER_ID#"},
      "genre" : [{"name" : "Broadcast Script", "qcode" : "Broadcast Script"}], "headline": "broadcast",
      "slugline" : "broadcast", "broadcast" : {"master_id" : "123"}, "type" : "text",
      "subject":[{"qcode": "17004000", "name": "Statistics"}], "body_html": "Test Document body", "_current_version": 2}
    ]
    """
    When we delete "/archived/123:2"
    Then we get error 400
    """
    {"_message": "Can't kill as this article acts as a Master Story for existing broadcast(s)"}
    """

    @auth
    Scenario: Fails to delete from archived with no privilege
      Given "archived"
      """
      [{"item_id": "123", "guid": "123", "type": "text", "headline": "test", "slugline": "slugline",
        "headline": "headline", "anpa_category" : [{"qcode" : "e", "name" : "Entertainment"}], "state": "published",
        "task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#", "user": "#CONTEXT_USER_ID#"},
        "subject":[{"qcode": "17004000", "name": "Statistics"}], "body_html": "Test Document body", "_current_version": 2}]
      """
      When we patch "/users/#CONTEXT_USER_ID#"
      """
      {"user_type": "user", "privileges": {"archive": 1, "unlock": 1, "tasks": 1, "users": 1}}
      """
      Then we get OK response
      When we delete "/archived/123:2"
      Then we get response code 403
      When we get "/archived"
      Then we get list with 1 items
