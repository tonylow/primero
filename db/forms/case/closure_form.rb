closure_fields = [
  Field.new({"name" => "closure_approved",
              "type" => "tick_box",
              "tick_box_label_en" => "Yes",
              "display_name_en" => "Approved by Manager",
              "disabled" => true,
              "editable" => false
            }),
  Field.new({"name" => "closure_approved_date",
             "type" => "date_field",
             "display_name_en" => "Date",
             "disabled" => true,
             "editable" => false
            }),
  Field.new({"name" => "closure_approved_comments",
             "type" => "textarea",
             "display_name_en" => "Manager Comments",
             "disabled" => true,
             "editable" => false
            }),
  Field.new({"name" => "approval_status_closure",
             "type" => "select_box",
             "display_name_en" => "Approval Status",
             "editable" => false,
             "disabled" => true,
             "option_strings_source" => "lookup lookup-approval-status"
            }),
  Field.new({"name" => "status",
             "type" =>"select_box" ,
             "selected_value" => Record::STATUS_OPEN,
             "display_name_en" => "Case Status",
             "option_strings_source" => "lookup lookup-case-status",
             "editable" => false,
             "disabled" => true
            }),
  Field.new({"name" => "closure_reason",
             "type" => "select_box",
             "display_name_en" => "What is the reason for closing the child's file?",
             "option_strings_text_en" => [
               { id: 'death_of_child', display_text: "Death of Child" },
               { id: 'formal_closing', display_text: "Formal Closing" },
               { id: 'not_seen_during_verification', display_text: "Not Seen During Verification" },
               { id: 'repatriated', display_text: "Repatriated" },
               { id: 'transferred', display_text: "Transferred" },
               { id: 'other', display_text: "Other" }
             ].map(&:with_indifferent_access)
            }),
  Field.new({"name" => "closure_reason_other",
             "type" => "text_field",
             "display_name_en" => "If other, please specify ",
            }),
  Field.new({"name" => "date_closure",
             "type" => "date_field",
             "display_name_en" => "Date of Closure",
            }),
  Field.new({"name" => "name_caregiver_closing",
             "type" => "text_field",
             "display_name_en" => "Caregiver Name",
            }),
  Field.new({"name" => "relationship_caregiver_closing",
             "type" => "text_field",
             "display_name_en" => "Caregiver Relationship",
            }),
  Field.new({"name" => "address_caregiver_closing",
             "type" => "textarea",
             "display_name_en" => "Caregiver Address",
            }),
  Field.new({"name" => "location_caregiver_closing",
             "type" => "select_box",
             "display_name_en" => "Caregiver Location",
             "option_strings_source" => "Location"
            })
]

FormSection.create_or_update!({
  :unique_id => "closure_form",
  :parent_form=>"case",
  "visible" => true,
  :order_form_group => 110,
  :order => 21,
  :order_subform => 0,
  :form_group_id => "closure",
  "editable" => true,
  :fields => closure_fields,
  "name_en" => "Closure",
  "description_en" => "Closure"
})
