/* eslint-disable react/display-name, react/prop-types */

import { Box } from "@material-ui/core";
import { Form } from "formik";
import React from "react";

import { UNIQUE_ID_FIELD, ID_FIELD, DISPLAY_TEXT_FIELD, NAME_FIELD } from "../../../../../config";
import { valuesToSearchableSelect } from "../../../../../libs";
import { internalFieldsDirty } from "../utils";
import { filterUsers } from "../../utils";

import BulkTransfer from "./bulk-transfer";
import { AGENCY_FIELD, LOCATION_FIELD, TRANSITIONED_TO_FIELD, NOTES_FIELD } from "./constants";
import ProvidedConsent from "./provided-consent";
import sharedControls from "./shared-controls";
import sharedOnChange from "./shared-on-change";
import TransferInternal from "./transfer-internal";

export default (
  props,
  isBulkTransfer,
  users,
  agencies,
  locations,
  recordType,
  setDisabled,
  disableControl,
  i18n,
  dispatch,
  providedConsent,
  canConsentOverride,
  record,
  mode
) => {
  const { handleSubmit, values, resetForm } = props;
  const { transfer } = values;

  const internalFields = [
    {
      id: AGENCY_FIELD,
      label: i18n.t("transfer.agency_label"),
      options: valuesToSearchableSelect(agencies, UNIQUE_ID_FIELD, NAME_FIELD, i18n.locale),
      onChange: (data, field, form) => {
        form.setFieldValue([TRANSITIONED_TO_FIELD], "", false);
        sharedOnChange(data, field, form, [LOCATION_FIELD], recordType, dispatch);
      }
    },
    {
      id: LOCATION_FIELD,
      label: i18n.t("transfer.location_label"),
      options: valuesToSearchableSelect(locations, ID_FIELD, DISPLAY_TEXT_FIELD, i18n.locale),
      onChange: (data, field, form) => {
        form.setFieldValue([TRANSITIONED_TO_FIELD], "", false);
        sharedOnChange(data, field, form, [AGENCY_FIELD], recordType, dispatch);
      }
    },
    {
      id: TRANSITIONED_TO_FIELD,
      label: i18n.t("transfer.recipient_label"),
      required: true,
      options: filterUsers(users, mode, record, true),
      onChange: (data, field, form) => {
        sharedOnChange(data, field, form);
      }
    },
    {
      id: NOTES_FIELD,
      label: i18n.t("transfer.notes_label")
    }
  ];

  if (
    !transfer &&
    !providedConsent &&
    internalFieldsDirty(
      values,
      internalFields.map(f => f.id)
    )
  ) {
    resetForm();
  }

  const providedConsentProps = {
    canConsentOverride,
    providedConsent,
    setDisabled,
    recordType
  };

  return (
    <Form onSubmit={handleSubmit}>
      <ProvidedConsent {...providedConsentProps} />
      <BulkTransfer isBulkTransfer={isBulkTransfer} />
      <Box>
        {sharedControls(i18n, disableControl)}
        <TransferInternal fields={internalFields} disableControl={disableControl} />
      </Box>
    </Form>
  );
};
