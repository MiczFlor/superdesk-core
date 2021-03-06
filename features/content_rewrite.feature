Feature: Rewrite content

    @auth
    Scenario: Rewrite a published content
      Given the "validators"
      """
        [
        {
            "schema": {},
            "type": "text",
            "act": "publish",
            "_id": "publish_text"
        },
        {
            "_id": "publish_composite",
            "act": "publish",
            "type": "composite",
            "schema": {}
        }
        ]
      """
      And "desks"
      """
      [{"name": "Sports"}]
      """
      And "archive"
      """
      [{"guid": "123", "type": "text", "headline": "test", "_current_version": 1, "state": "fetched",
        "task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#", "user": "#CONTEXT_USER_ID#"},
        "subject":[{"qcode": "17004000", "name": "Statistics"}],
        "body_html": "Test Document body", "genre": [{"name": "Article", "qcode": "Article"}],
        "flags": {"marked_for_legal": true},
        "body_footer": "Suicide Call Back Service 1300 659 467",
        "place": [{"qcode" : "ACT", "world_region" : "Oceania", "country" : "Australia",
        "name" : "ACT", "state" : "Australian Capital Territory"}],
        "company_codes" : [{"qcode" : "1PG", "security_exchange" : "ASX", "name" : "1-PAGE LIMITED"}]
      }]
      """
      When we post to "/stages"
      """
      [
        {
        "name": "another stage",
        "description": "another stage",
        "task_status": "in_progress",
        "desk": "#desks._id#"
        }
      ]
      """
      And we post to "/archive/123/move"
        """
        [{"task": {"desk": "#desks._id#", "stage": "#stages._id#"}}]
        """
      Then we get OK response
      When we post to "/products" with success
      """
      {
        "name":"prod-1","codes":"abc,xyz"
      }
      """
      And we post to "/subscribers" with success
      """
      {
        "name":"Channel 3","media_type":"media", "subscriber_type": "digital", "sequence_num_settings":{"min" : 1, "max" : 10}, "email": "test@test.com",
        "products": ["#products._id#"],
        "destinations":[{"name":"Test","format": "nitf", "delivery_type":"email","config":{"recipients":"test@test.com"}}]
      }
      """
      And we publish "#archive._id#" with "publish" type and "published" state
      Then we get OK response
      And we get existing resource
      """
      {"_current_version": 3, "state": "published", "task":{"desk": "#desks._id#", "stage": "#stages._id#"}}
      """
      When we get "/published"
      Then we get existing resource
      """
      {"_items" : [{"_id": "123", "guid": "123", "headline": "test", "_current_version": 3, "state": "published",
        "task": {"desk": "#desks._id#", "stage": "#stages._id#", "user": "#CONTEXT_USER_ID#"}}]}
      """
      When we rewrite "123"
      """
      {"desk_id": "#desks._id#"}
      """
      When we get "/published"
      Then we get existing resource
      """
      {"_items" : [{"_id": "123", "rewritten_by": "#REWRITE_ID#"},
                   {"package_type": "takes", "rewritten_by": "#REWRITE_ID#"}]}
      """
      When we get "/archive"
      Then we get existing resource
      """
      {"_items" : [{"_id": "#REWRITE_ID#", "anpa_take_key": "update", "rewrite_of": "#archive.123.take_package#",
        "task": {"desk": "#desks._id#", "stage": "#desks.working_stage#"}, "genre": [{"name": "Article", "qcode": "Article"}],
        "flags": {"marked_for_legal": true},
        "body_footer": "Suicide Call Back Service 1300 659 467",
        "company_codes" : [{"qcode" : "1PG", "security_exchange" : "ASX", "name" : "1-PAGE LIMITED"}],
        "place": [{"qcode" : "ACT"}]}]}
      """
      When we get "/archive/123"
      Then we get existing resource
      """
      {"_id": "123", "rewritten_by": "#REWRITE_ID#", "place": [{"qcode" : "ACT"}]}
      """

    @auth
    Scenario: Rewrite the non-last take fails
        Given the "validators"
        """
        [{"_id": "publish_text", "act": "publish", "type": "text", "schema":{}}]
        """
    	And empty "ingest"
    	And "desks"
        """
        [{"name": "Sports"}]
        """
        When we post to "/products" with success
        """
        {
          "name":"prod-1","codes":"abc,xyz"
        }
        """
        And we post to "/subscribers" with success
        """
        {
          "name":"News1","media_type":"media", "subscriber_type": "digital",
          "sequence_num_settings":{"min" : 1, "max" : 10}, "email": "test@test.com",
          "products": ["#products._id#"],
          "destinations":[{"name":"destination1","format": "nitf", "delivery_type":"FTP","config":{"ip":"144.122.244.55","password":"xyz"}}]
        }
        """
    	And we post to "archive" with success
        """
        [{
            "guid": "123",
            "type": "text",
            "headline": "Take-1 headline",
            "abstract": "Take-1 abstract",
            "task": {
                "user": "#CONTEXT_USER_ID#"
            },
            "body_html": "Take-1",
            "state": "draft",
            "slugline": "Take-1 slugline",
            "urgency": "4",
            "pubstatus": "usable",
            "subject":[{"qcode": "17004000", "name": "Statistics"}],
            "anpa_category": [{"qcode": "A", "name": "Sport"}],
            "anpa_take_key": "Take"
        }]
        """
        And we post to "/archive/123/move"
        """
        [{"task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#"}}]
        """
        Then we get OK response
        When we post to "archive/123/link"
        """
        [{}]
        """
        Then we get next take as "TAKE"
        """
        {
            "_id": "#TAKE#",
            "type": "text",
            "headline": "Take-1 headline",
            "slugline": "Take-1 slugline",
            "anpa_take_key": "Take=2",
            "state": "draft",
            "original_creator": "#CONTEXT_USER_ID#",
            "takes": {
                "_id": "#TAKE_PACKAGE#",
                "package_type": "takes",
                "type": "composite"
            },
            "linked_in_packages": [{"package_type" : "takes","package" : "#TAKE_PACKAGE#"}]
        }
        """
        When we patch "/archive/#TAKE#"
        """
        {"body_html": "Take-2", "abstract": "Take-1 abstract changed"}
        """
        And we post to "/archive/#TAKE#/move"
        """
        [{"task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#"}}]
        """
		And we get "/archive"
        Then we get list with 3 items
        When we publish "123" with "publish" type and "published" state
        Then we get OK response
        When we post to "archive/#TAKE#/link"
        """
        [{}]
        """
        Then we get next take as "TAKE2"
        """
        {
            "_id": "#TAKE2#",
            "type": "text",
            "headline": "Take-1 headline",
            "slugline": "Take-1 slugline",
            "anpa_take_key": "Take=3",
            "state": "draft",
            "original_creator": "#CONTEXT_USER_ID#",
            "takes": {
                "_id": "#TAKE_PACKAGE#",
                "package_type": "takes",
                "type": "composite"
            },
            "linked_in_packages": [{"package_type" : "takes","package" : "#TAKE_PACKAGE#"}]
        }
        """
        When we rewrite "123"
        """
        {"desk_id": "#desks._id#"}
        """
        Then we get error 400
        """
        {"_message": "Only last take of the package can be rewritten."}
        """

    @auth
    Scenario: Rewrite the last take succeeds
        Given the "validators"
        """
        [{"_id": "publish_text", "act": "publish", "type": "text", "schema":{}}]
        """
    	And empty "ingest"
    	And "desks"
        """
        [{"name": "Sports"}]
        """
        When we post to "/products" with success
        """
        {
          "name":"prod-1","codes":"abc,xyz"
        }
        """
        And we post to "/subscribers" with success
        """
        {
          "name":"News1","media_type":"media", "subscriber_type": "digital",
          "sequence_num_settings":{"min" : 1, "max" : 10}, "email": "test@test.com",
          "products": ["#products._id#"],
          "destinations":[{"name":"destination1","format": "nitf", "delivery_type":"FTP","config":{"ip":"144.122.244.55","password":"xyz"}}]
        }
        """
    	And we post to "archive" with success
        """
        [{
            "guid": "123",
            "type": "text",
            "headline": "Take-1 headline",
            "abstract": "Take-1 abstract",
            "task": {
                "user": "#CONTEXT_USER_ID#"
            },
            "body_html": "Take-1",
            "state": "draft",
            "slugline": "Take-1 slugline",
            "urgency": "4",
            "pubstatus": "usable",
            "subject":[{"qcode": "17004000", "name": "Statistics"}],
            "anpa_category": [{"qcode": "A", "name": "Sport"}],
            "anpa_take_key": "Take"
        }]
        """
        And we post to "/archive/123/move"
        """
        [{"task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#"}}]
        """
        Then we get OK response
        When we post to "archive/123/link"
        """
        [{}]
        """
        Then we get next take as "TAKE"
        """
        {
            "_id": "#TAKE#",
            "type": "text",
            "headline": "Take-1 headline",
            "slugline": "Take-1 slugline",
            "anpa_take_key": "Take=2",
            "state": "draft",
            "original_creator": "#CONTEXT_USER_ID#",
            "takes": {
                "_id": "#TAKE_PACKAGE#",
                "package_type": "takes",
                "type": "composite"
            },
            "linked_in_packages": [{"package_type" : "takes","package" : "#TAKE_PACKAGE#"}]
        }
        """
        When we patch "/archive/#TAKE#"
        """
        {"body_html": "Take-2", "abstract": "Take-1 abstract changed"}
        """
        And we post to "/archive/#TAKE#/move"
        """
        [{"task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#"}}]
        """
		And we get "/archive"
        Then we get list with 3 items
        When we publish "123" with "publish" type and "published" state
        Then we get OK response
        When we publish "#TAKE#" with "publish" type and "published" state
        Then we get OK response
        When we rewrite "#TAKE#"
        """
        {"desk_id": "#desks._id#"}
        """
        When we get "/published"
        Then we get existing resource
        """
        {"_items" : [{"_id": "123"},
                     {"package_type": "takes", "rewritten_by": "#REWRITE_ID#"},
                     {"_id": "#TAKE#", "rewritten_by": "#REWRITE_ID#"}]}
        """
        When we get "/archive"
        Then we get existing resource
        """
        {"_items" : [{"_id": "#REWRITE_ID#", "anpa_take_key": "update", "rewrite_of": "#archive.123.take_package#",
          "task": {"desk": "#desks._id#"}}]}
        """

    @auth
      Scenario: Rewrite of a rewritten published content
        Given the "validators"
        """
          [
          {
              "schema": {},
              "type": "text",
              "act": "publish",
              "_id": "publish_text"
          },
          {
              "_id": "publish_composite",
              "act": "publish",
              "type": "composite",
              "schema": {}
          }
          ]
        """
        And "desks"
        """
        [{"name": "Sports"}]
        """
        And "archive"
        """
        [{"guid": "123", "type": "text", "headline": "test", "_current_version": 1, "state": "fetched",
          "task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#", "user": "#CONTEXT_USER_ID#"},
          "subject":[{"qcode": "17004000", "name": "Statistics"}],
          "body_html": "Test Document body"}]
        """
        When we post to "/products" with success
        """
        {
          "name":"prod-1","codes":"abc,xyz"
        }
        """
        And we post to "/subscribers" with success
        """
        {
          "name":"Channel 3","media_type":"media", "subscriber_type": "digital", "sequence_num_settings":{"min" : 1, "max" : 10}, "email": "test@test.com",
          "products": ["#products._id#"],
          "destinations":[{"name":"Test","format": "nitf", "delivery_type":"email","config":{"recipients":"test@test.com"}}]
        }
        """
        And we publish "#archive._id#" with "publish" type and "published" state
        When we rewrite "123"
        """
        {"desk_id": "#desks._id#"}
        """
        And we patch "archive/#REWRITE_ID#"
        """
        {"abstract": "test", "body_html": "Test Document body"}
        """
        When we publish "#REWRITE_ID#" with "publish" type and "published" state
        When we get "/published"
        Then we get existing resource
        """
        {"_items" : [{"_id": "123", "rewritten_by": "#REWRITE_ID#"},
                     {"package_type": "takes", "rewritten_by": "#REWRITE_ID#"},
                     {"_id": "#REWRITE_ID#", "anpa_take_key": "update"}]}
        """
        When we rewrite "#REWRITE_ID#"
        """
        {"desk_id": "#desks._id#"}
        """
        When we get "/archive"
        Then we get existing resource
        """
        {"_items" : [{"_id": "#REWRITE_ID#", "anpa_take_key": "2nd update",
          "task": {"desk": "#desks._id#"}}]}
        """

    @auth
    Scenario: Spike of an unpublished rewrite removes references
      Given the "validators"
      """
        [
        {
            "schema": {},
            "type": "text",
            "act": "publish",
            "_id": "publish_text"
        },
        {
            "_id": "publish_composite",
            "act": "publish",
            "type": "composite",
            "schema": {}
        }
        ]
      """
      And "desks"
      """
      [{"name": "Sports"}]
      """
      And "archive"
      """
      [{"guid": "123", "type": "text", "headline": "test", "_current_version": 1, "state": "fetched",
        "task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#", "user": "#CONTEXT_USER_ID#"},
        "subject":[{"qcode": "17004000", "name": "Statistics"}],
        "body_html": "Test Document body"}]
      """
      When we post to "/products" with success
      """
      {
        "name":"prod-1","codes":"abc,xyz"
      }
      """
      And we post to "/subscribers" with success
      """
      {
        "name":"Channel 3","media_type":"media", "subscriber_type": "digital", "sequence_num_settings":{"min" : 1, "max" : 10}, "email": "test@test.com",
        "products": ["#products._id#"],
        "destinations":[{"name":"Test","format": "nitf", "delivery_type":"email","config":{"recipients":"test@test.com"}}]
      }
      """
      And we publish "#archive._id#" with "publish" type and "published" state
      Then we get OK response
      And we get existing resource
      """
      {"_current_version": 2, "state": "published", "task":{"desk": "#desks._id#", "stage": "#desks.incoming_stage#"}}
      """
      When we get "/published"
      Then we get existing resource
      """
      {"_items" : [{"_id": "123", "guid": "123", "headline": "test", "_current_version": 2, "state": "published",
        "task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#", "user": "#CONTEXT_USER_ID#"}}]}
      """
      When we rewrite "123"
      """
      {"desk_id": "#desks._id#"}
      """
      When we get "/published"
      Then we get existing resource
      """
      {"_items" : [{"_id": "123", "rewritten_by": "#REWRITE_ID#"},
                   {"package_type": "takes", "rewritten_by": "#REWRITE_ID#"}]}
      """
      When we get "/archive"
      Then we get existing resource
      """
      {"_items" : [{"_id": "#REWRITE_ID#", "anpa_take_key": "update", "rewrite_of": "#archive.123.take_package#",
        "task": {"desk": "#desks._id#"}}]}
      """
      When we spike "#REWRITE_ID#"
      Then we get OK response
      And we get spiked content "#REWRITE_ID#"
      And we get "rewrite_of" not populated
      When we get "/published"
      Then we get "rewritten_by" not populated in results
      When we get "/archive/123"
      Then we get "rewritten_by" not populated

    @auth
    Scenario: Spike of an unpublished rewrite of a rewrite removes references from last rewrite
    Given the "validators"
      """
        [
        {
            "schema": {},
            "type": "text",
            "act": "publish",
            "_id": "publish_text"
        },
        {
            "_id": "publish_composite",
            "act": "publish",
            "type": "composite",
            "schema": {}
        }
        ]
      """
      And "desks"
      """
      [{"name": "Sports"}]
      """
      And "archive"
      """
      [{"guid": "123", "type": "text", "headline": "test", "_current_version": 1, "state": "fetched",
        "task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#", "user": "#CONTEXT_USER_ID#"},
        "subject":[{"qcode": "17004000", "name": "Statistics"}],
        "body_html": "Test Document body"}]
      """
      When we post to "/products" with success
      """
      {
        "name":"prod-1","codes":"abc,xyz"
      }
      """
      And we post to "/subscribers" with success
      """
      {
        "name":"Channel 3","media_type":"media", "subscriber_type": "digital", "sequence_num_settings":{"min" : 1, "max" : 10}, "email": "test@test.com",
        "products": ["#products._id#"],
        "destinations":[{"name":"Test","format": "nitf", "delivery_type":"email","config":{"recipients":"test@test.com"}}]
      }
      """
      And we publish "#archive._id#" with "publish" type and "published" state
      When we rewrite "123"
      """
      {"desk_id": "#desks._id#"}
      """
      And we patch "archive/#REWRITE_ID#"
      """
      {"abstract": "test", "body_html": "Test Document body"}
      """
      When we publish "#REWRITE_ID#" with "publish" type and "published" state
      When we get "/published"
      Then we get existing resource
      """
      {"_items" : [{"_id": "123", "rewritten_by": "#REWRITE_ID#"},
                   {"package_type": "takes", "rewritten_by": "#REWRITE_ID#"},
                   {"_id": "#REWRITE_ID#", "anpa_take_key": "update"}]}
      """
      When we rewrite "#REWRITE_ID#"
      """
      {"desk_id": "#desks._id#"}
      """
      When we get "/archive"
      Then we get existing resource
      """
      {"_items" : [{"_id": "#REWRITE_ID#", "anpa_take_key": "2nd update",
        "task": {"desk": "#desks._id#"}}]}
      """
      When we spike "#REWRITE_ID#"
      Then we get OK response
      And we get spiked content "#REWRITE_ID#"
      And we get "rewrite_of" not populated
      When we get "/published"
      Then we get existing resource
      """
      {"_items": [{"_id": "123", "rewritten_by": "#REWRITE_OF#"}]}
      """

    @auth
      Scenario: A new take on a rewritten story fails
        Given the "validators"
        """
          [
          {
              "schema": {},
              "type": "text",
              "act": "publish",
              "_id": "publish_text"
          },
          {
              "_id": "publish_composite",
              "act": "publish",
              "type": "composite",
              "schema": {}
          }
          ]
        """
        And "desks"
        """
        [{"name": "Sports"}]
        """
        And "archive"
        """
        [{"guid": "123", "type": "text", "headline": "test", "_current_version": 1, "state": "fetched",
          "task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#", "user": "#CONTEXT_USER_ID#"},
          "subject":[{"qcode": "17004000", "name": "Statistics"}],
          "body_html": "Test Document body"}]
        """
        When we post to "/products" with success
        """
        {
          "name":"prod-1","codes":"abc,xyz"
        }
        """
        And we post to "/subscribers" with success
        """
        {
          "name":"Channel 3","media_type":"media", "subscriber_type": "digital", "sequence_num_settings":{"min" : 1, "max" : 10}, "email": "test@test.com",
          "products": ["#products._id#"],
          "destinations":[{"name":"Test","format": "nitf", "delivery_type":"email","config":{"recipients":"test@test.com"}}]
        }
        """
        And we publish "#archive._id#" with "publish" type and "published" state
        When we rewrite "123"
        """
        {"desk_id": "#desks._id#"}
        """
        And we patch "archive/#REWRITE_ID#"
        """
        {"abstract": "test", "body_html": "Test Document body"}
        """
        When we publish "#REWRITE_ID#" with "publish" type and "published" state
        When we get "/published"
        Then we get existing resource
        """
        {"_items" : [{"_id": "123", "rewritten_by": "#REWRITE_ID#"},
                     {"package_type": "takes", "rewritten_by": "#REWRITE_ID#"},
                     {"_id": "#REWRITE_ID#", "anpa_take_key": "update"}]}
        """
        When we post to "archive/123/link"
        """
        [{}]
        """
        Then we get error 400
        """
        {"_message": "Article has been rewritten before !"}
        """

    @auth
    Scenario: A new take on a published rewrite succeeds
        Given the "validators"
        """
          [
          {
              "schema": {},
              "type": "text",
              "act": "publish",
              "_id": "publish_text"
          },
          {
              "_id": "publish_composite",
              "act": "publish",
              "type": "composite",
              "schema": {}
          }
          ]
        """
        And "desks"
        """
        [{"name": "Sports"}]
        """
        And "archive"
        """
        [{"guid": "123", "type": "text", "headline": "test", "_current_version": 1, "state": "fetched",
          "task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#", "user": "#CONTEXT_USER_ID#"},
          "subject":[{"qcode": "17004000", "name": "Statistics"}],
          "body_html": "Test Document body"}]
        """
        When we post to "/products" with success
        """
        {
          "name":"prod-1","codes":"abc,xyz"
        }
        """
        And we post to "/subscribers" with success
        """
        {
          "name":"Channel 3","media_type":"media", "subscriber_type": "digital", "sequence_num_settings":{"min" : 1, "max" : 10}, "email": "test@test.com",
          "products": ["#products._id#"],
          "destinations":[{"name":"Test","format": "nitf", "delivery_type":"email","config":{"recipients":"test@test.com"}}]
        }
        """
        And we publish "#archive._id#" with "publish" type and "published" state
        When we rewrite "123"
        """
        {"desk_id": "#desks._id#"}
        """
        And we patch "archive/#REWRITE_ID#"
        """
        {"abstract": "test", "body_html": "Test Document body", "headline": "RETAKE", "slugline": "RETAKE"}
        """
        When we publish "#REWRITE_ID#" with "publish" type and "published" state
        When we get "/published"
        Then we get existing resource
        """
        {"_items" : [{"_id": "123", "rewritten_by": "#REWRITE_ID#"},
                     {"package_type": "takes", "rewritten_by": "#REWRITE_ID#"},
                     {"_id": "#REWRITE_ID#", "anpa_take_key": "update"}]}
        """
        When we post to "archive/#REWRITE_ID#/link"
        """
        [{}]
        """
        Then we get next take as "TAKE"
        """
        {
            "_id": "#TAKE#",
            "type": "text",
            "headline": "RETAKE",
            "slugline": "RETAKE",
            "anpa_take_key": "update (reopens)=2",
            "state": "draft",
            "original_creator": "#CONTEXT_USER_ID#",
            "takes": {
                "_id": "#TAKE_PACKAGE#",
                "package_type": "takes",
                "type": "composite"
            },
            "linked_in_packages": [{"package_type" : "takes","package" : "#TAKE_PACKAGE#"}]
        }
        """

    @auth
    Scenario: Associate a story as update
      Given the "validators"
      """
        [
        {
            "schema": {},
            "type": "text",
            "act": "publish",
            "_id": "publish_text"
        },
        {
            "_id": "publish_composite",
            "act": "publish",
            "type": "composite",
            "schema": {}
        }
        ]
      """
      And "desks"
      """
      [{"name": "Sports"}]
      """
      And "archive"
      """
      [{"guid": "123", "type": "text", "headline": "test", "_current_version": 1, "state": "fetched",
        "task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#", "user": "#CONTEXT_USER_ID#"},
        "subject":[{"qcode": "17004000", "name": "Statistics"}],
        "body_html": "Test Document body", "genre": [{"name": "Article", "value": "Article"}],
        "flags": {"marked_for_legal": true},
        "body_footer": "Suicide Call Back Service 1300 659 467",
        "place": [{"qcode" : "ACT", "world_region" : "Oceania", "country" : "Australia",
        "name" : "ACT", "state" : "Australian Capital Territory"}],
        "company_codes" : [{"qcode" : "1PG", "security_exchange" : "ASX", "name" : "1-PAGE LIMITED"}]
      },{"guid": "456", "type": "text", "headline": "test", "_current_version": 1, "state": "submitted"}]
      """
      When we post to "/stages"
      """
      [
        {
        "name": "another stage",
        "description": "another stage",
        "task_status": "in_progress",
        "desk": "#desks._id#"
        }
      ]
      """
      And we post to "/archive/123/move"
        """
        [{"task": {"desk": "#desks._id#", "stage": "#stages._id#"}}]
        """
      Then we get OK response
      When we post to "/products" with success
      """
      {
        "name":"prod-1","codes":"abc,xyz"
      }
      """
      And we post to "/subscribers" with success
      """
      {
        "name":"Channel 3","media_type":"media", "subscriber_type": "digital", "sequence_num_settings":{"min" : 1, "max" : 10}, "email": "test@test.com",
        "products": ["#products._id#"],
        "destinations":[{"name":"Test","format": "nitf", "delivery_type":"email","config":{"recipients":"test@test.com"}}]
      }
      """
      And we publish "123" with "publish" type and "published" state
      Then we get OK response
      And we get existing resource
      """
      {"_current_version": 3, "state": "published", "task":{"desk": "#desks._id#", "stage": "#stages._id#"}}
      """
      When we get "/published"
      Then we get existing resource
      """
      {"_items" : [{"_id": "123", "guid": "123", "headline": "test", "_current_version": 3, "state": "published",
        "task": {"desk": "#desks._id#", "stage": "#stages._id#", "user": "#CONTEXT_USER_ID#"}}]}
      """
      When we rewrite "123"
      """
      {"update": {"_id": "456", "type": "text", "headline": "test", "_current_version": 1, "state": "submitted"}}
      """
      When we get "/published"
      Then we get existing resource
      """
      {"_items" : [{"_id": "123", "rewritten_by": "456"},
                   {"package_type": "takes", "rewritten_by": "456"}]}
      """
      When we get "/archive/456"
      Then we get existing resource
      """
      {"_id": "456", "anpa_take_key": "update", "rewrite_of": "#archive.123.take_package#"}
      """
      When we get "/archive/123"
      Then we get existing resource
      """
      {"_id": "123", "rewritten_by": "456", "place": [{"qcode" : "ACT"}]}
      """

    @auth
    Scenario: Fail to publish original story after rewrite is published
        Given the "validators"
        """
          [
          {
              "schema": {},
              "type": "text",
              "act": "publish",
              "_id": "publish_text"
          },
          {
              "_id": "publish_composite",
              "act": "publish",
              "type": "composite",
              "schema": {}
          }
          ]
        """
        And "desks"
        """
        [{"name": "Sports"}]
        """
        And "archive"
        """
        [{"guid": "123", "type": "text", "headline": "test", "_current_version": 1, "state": "fetched",
          "task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#", "user": "#CONTEXT_USER_ID#"},
          "subject":[{"qcode": "17004000", "name": "Statistics"}],
          "body_html": "Test Document body"}]
        """
        When we post to "/products" with success
        """
        {
          "name":"prod-1","codes":"abc,xyz"
        }
        """
        And we post to "/subscribers" with success
        """
        {
          "name":"Channel 3","media_type":"media", "subscriber_type": "digital", "sequence_num_settings":{"min" : 1, "max" : 10}, "email": "test@test.com",
          "products": ["#products._id#"],
          "destinations":[{"name":"Test","format": "nitf", "delivery_type":"email","config":{"recipients":"test@test.com"}}]
        }
        """
        When we rewrite "123"
        """
        {"desk_id": "#desks._id#"}
        """
        And we patch "archive/#REWRITE_ID#"
        """
        {"abstract": "test", "body_html": "Test Document body", "headline": "RETAKE", "slugline": "RETAKE"}
        """
        When we publish "#REWRITE_ID#" with "publish" type and "published" state
        When we get "/published"
        Then we get existing resource
        """
        {"_items" : [{"_id": "#REWRITE_ID#", "anpa_take_key": "update"}]}
        """
        When we publish "123" with "publish" type and "published" state
        Then we get error 400
        """
        {"_status": "ERR",
         "_issues": {"validator exception": "400: Cannot publish the story after Update is published.!"}}
        """

    @auth
    Scenario: Fail to publish last take after rewrite is published
        Given the "validators"
        """
          [
          {
              "schema": {},
              "type": "text",
              "act": "publish",
              "_id": "publish_text"
          },
          {
              "_id": "publish_composite",
              "act": "publish",
              "type": "composite",
              "schema": {}
          }
          ]
        """
        And "desks"
        """
        [{"name": "Sports"}]
        """
        And "archive"
        """
        [{"guid": "123", "type": "text", "headline": "test", "_current_version": 1, "state": "fetched",
          "task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#", "user": "#CONTEXT_USER_ID#"},
          "subject":[{"qcode": "17004000", "name": "Statistics"}],
          "body_html": "Test Document body"}]
        """
        When we post to "/products" with success
        """
        {
          "name":"prod-1","codes":"abc,xyz"
        }
        """
        And we post to "/subscribers" with success
        """
        {
          "name":"Channel 3","media_type":"media", "subscriber_type": "digital", "sequence_num_settings":{"min" : 1, "max" : 10}, "email": "test@test.com",
          "products": ["#products._id#"],
          "destinations":[{"name":"Test","format": "nitf", "delivery_type":"email","config":{"recipients":"test@test.com"}}]
        }
        """
        Then we get OK response
        When we post to "archive/123/link"
        """
        [{}]
        """
        Then we get next take as "TAKE"
        """
        {
            "_id": "#TAKE#",
            "type": "text",
            "headline": "test",
            "anpa_take_key": "=2",
            "state": "draft",
            "original_creator": "#CONTEXT_USER_ID#",
            "takes": {
                "_id": "#TAKE_PACKAGE#",
                "package_type": "takes",
                "type": "composite"
            },
            "linked_in_packages": [{"package_type" : "takes","package" : "#TAKE_PACKAGE#"}]
        }
        """
        When we patch "/archive/#TAKE#"
        """
        {"body_html": "Take-2", "abstract": "Take-1 abstract changed"}
        """
        And we post to "/archive/#TAKE#/move"
        """
        [{"task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#"}}]
        """
		And we get "/archive"
        Then we get list with 3 items
        When we rewrite "#TAKE#"
        """
        {"desk_id": "#desks._id#"}
        """
        And we patch "archive/#REWRITE_ID#"
        """
        {"abstract": "test", "body_html": "Test Document body", "headline": "RETAKE", "slugline": "RETAKE"}
        """
        Then we get OK response
        When we publish "123" with "publish" type and "published" state
        Then we get OK response
        When we publish "#REWRITE_ID#" with "publish" type and "published" state
        Then we get OK response
        When we publish "#TAKE#" with "publish" type and "published" state
        Then we get error 400
        """
        {"_status": "ERR",
         "_issues": {"validator exception": "400: Cannot publish the story after Update is published.!"}}
        """

    @auth
    Scenario: Link the rewrite to the 2nd last take if the last take is spiked
        Given the "validators"
        """
          [
          {
              "schema": {},
              "type": "text",
              "act": "publish",
              "_id": "publish_text"
          },
          {
              "_id": "publish_composite",
              "act": "publish",
              "type": "composite",
              "schema": {}
          }
          ]
        """
        And "desks"
        """
        [{"name": "Sports"}]
        """
        And "archive"
        """
        [{"guid": "123", "type": "text", "headline": "test", "_current_version": 1, "state": "fetched",
          "task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#", "user": "#CONTEXT_USER_ID#"},
          "subject":[{"qcode": "17004000", "name": "Statistics"}],
          "body_html": "Test Document body"}]
        """
        When we post to "/products" with success
        """
        {
          "name":"prod-1","codes":"abc,xyz"
        }
        """
        And we post to "/subscribers" with success
        """
        {
          "name":"Channel 3","media_type":"media", "subscriber_type": "digital", "sequence_num_settings":{"min" : 1, "max" : 10}, "email": "test@test.com",
          "products": ["#products._id#"],
          "destinations":[{"name":"Test","format": "nitf", "delivery_type":"email","config":{"recipients":"test@test.com"}}]
        }
        """
        Then we get OK response
        When we post to "archive/123/link"
        """
        [{}]
        """
        Then we get next take as "TAKE"
        """
        {
            "_id": "#TAKE#",
            "type": "text",
            "headline": "test",
            "anpa_take_key": "=2",
            "state": "draft",
            "original_creator": "#CONTEXT_USER_ID#",
            "takes": {
                "_id": "#TAKE_PACKAGE#",
                "package_type": "takes",
                "type": "composite"
            },
            "linked_in_packages": [{"package_type" : "takes","package" : "#TAKE_PACKAGE#"}]
        }
        """
        When we patch "/archive/#TAKE#"
        """
        {"body_html": "Take-2", "abstract": "Take-1 abstract changed"}
        """
        And we post to "/archive/#TAKE#/move"
        """
        [{"task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#"}}]
        """
        Then we get OK response
        When we rewrite "#TAKE#"
        """
        {"desk_id": "#desks._id#"}
        """
        And we patch "archive/#REWRITE_ID#"
        """
        {"abstract": "test", "body_html": "Test Document body",
         "headline": "RETAKE", "slugline": "RETAKE", "rewrite_of": "#TAKE_PACKAGE#"}
        """
        Then we get OK response
        When we get "/archive/#TAKE#"
        Then we get existing resource
        """
        {"_id": "#TAKE#", "rewritten_by": "#REWRITE_ID#"}
        """
        When we get "/archive/#TAKE_PACKAGE#"
        Then we get existing resource
        """
        {"_id": "#TAKE_PACKAGE#", "rewritten_by": "#REWRITE_ID#"}
        """
        When we get "/archive/123"
        Then we get no "rewritten_by"
        When we spike "#TAKE#"
        Then we get OK response
        And we get spiked content "#TAKE#"
        And we get "rewritten_by" not populated
        When we get "/archive/123"
        Then we get existing resource
        """
        {"_id": "123", "rewritten_by": "#REWRITE_ID#"}
        """
        When we get "archive/#REWRITE_ID#"
        Then we get existing resource
        """
        {"abstract": "test", "body_html": "Test Document body",
         "headline": "RETAKE", "slugline": "RETAKE", "rewrite_of": "#TAKE_PACKAGE#"}
        """

    @auth
    Scenario: Cannot create rewrite of a rewrite if the original rewrite is not published
        Given the "validators"
        """
          [
          {
              "schema": {},
              "type": "text",
              "act": "publish",
              "_id": "publish_text"
          },
          {
              "_id": "publish_composite",
              "act": "publish",
              "type": "composite",
              "schema": {}
          }
          ]
        """
        And "desks"
        """
        [{"name": "Sports"}]
        """
        And "archive"
        """
        [{"guid": "123", "type": "text", "headline": "test", "_current_version": 1, "state": "fetched",
          "task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#", "user": "#CONTEXT_USER_ID#"},
          "subject":[{"qcode": "17004000", "name": "Statistics"}],
          "body_html": "Test Document body"}]
        """
        When we post to "/products" with success
        """
        {
          "name":"prod-1","codes":"abc,xyz"
        }
        """
        And we post to "/subscribers" with success
        """
        {
          "name":"Channel 3","media_type":"media", "subscriber_type": "digital", "sequence_num_settings":{"min" : 1, "max" : 10}, "email": "test@test.com",
          "products": ["#products._id#"],
          "destinations":[{"name":"Test","format": "nitf", "delivery_type":"email","config":{"recipients":"test@test.com"}}]
        }
        """
        Then we get OK response
        When we rewrite "123"
        """
        {"desk_id": "#desks._id#"}
        """
        And we patch "archive/#REWRITE_ID#"
        """
        {"abstract": "test", "body_html": "Test Document body", "headline": "RETAKE", "slugline": "RETAKE"}
        """
        Then we get OK response
        When we rewrite "#REWRITE_ID#"
        """
        {"desk_id": "#desks._id#"}
        """
        Then we get error 400
        """
        {"_status": "ERR",
         "_message": "Rewrite is not published. Cannot rewrite the story again."}
        """

    @auth
    @content_type
    Scenario: Archive rewrite should preserve profile and metadata specific to that profile
        Given "desks"
        """
        [{"name": "Sports"}]
        """
        And "archive"
        """
        [{"type":"text", "headline": "Rewrite preserves profile", "_id": "xyz", "profile": "story",
          "subject": [{"scheme": "territory", "qcode": "paterritory:uk", "name": "UK"}],
          "task": {"desk": "#desks._id#", "stage": "#desks.incoming_stage#", "user": "#CONTEXT_USER_ID#"}}]
        """
        When we rewrite "xyz"
        """
        {"desk_id": "#desks._id#"}
        """
        And we get "/archive"
        Then we get existing resource
        """
        {"_items" : [{"headline": "Rewrite preserves profile", "profile": "story",
         "subject": [{"scheme": "territory", "qcode": "paterritory:uk", "name": "UK"}],
         "task": {"desk": "#desks._id#"}}]}
        """
