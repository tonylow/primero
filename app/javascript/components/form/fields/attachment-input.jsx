import React, { useState } from "react";
import PropTypes from "prop-types";
import { InputLabel, FormHelperText } from "@material-ui/core";
import { useFormContext } from "react-hook-form";
import { makeStyles } from "@material-ui/core/styles";
import clsx from "clsx";

import { useI18n } from "../../i18n";
import { toBase64 } from "../../../libs";
import { PHOTO_FIELD, DOCUMENT_FIELD } from "../constants";
import ActionButton from "../../action-button";
import { ACTION_BUTTON_TYPES } from "../../action-button/constants";
import { ATTACHMENT_TYPES } from "../../record-form/form/field-types/attachments/constants";

import styles from "./styles.css";

const AttachmentInput = ({ commonInputProps, metaInputProps }) => {
  const { setValue, watch, register } = useFormContext();
  const i18n = useI18n();
  const css = makeStyles(styles)();
  const [file, setFile] = useState({
    loading: false,
    data: null,
    fileName: ""
  });

  const { type } = metaInputProps;
  const { name, label, disabled, helperText, error } = commonInputProps;
  const attachment = type === DOCUMENT_FIELD ? ATTACHMENT_TYPES.document : type;
  const isDocument = attachment === ATTACHMENT_TYPES.document;
  const acceptedTypes = isDocument ? ".csv" : "*";

  const fileBase64 = watch(`${name}_base64`);
  const fileUrl = watch(`${name}_url`);

  const loadingFile = (loading, data) => {
    setFile({
      loading,
      data: `${data?.content}${data?.result}`,
      fileName: data?.fileName
    });
  };

  const handleChange = async event => {
    const files = event?.target?.files;
    const selectedFile = files?.[0];

    loadingFile(true);

    if (selectedFile) {
      const data = await toBase64(selectedFile, attachment);

      if (data) {
        setValue(`${name}_base64`, data.result);
        setValue(`${name}_file_name`, data.fileName);
        loadingFile(false, data);
      }
    }
  };

  const fieldDisabled = () => file.loading || Boolean(fileBase64 && !file?.data);

  // eslint-disable-next-line react/no-multi-comp, react/display-name
  const renderPreview = () => {
    const { data, fileName } = file;

    return (data || fileUrl) && type === PHOTO_FIELD ? (
      <div>
        <img src={data || fileUrl} alt="" className={css.preview} />
      </div>
    ) : (
      <span>{fileName}</span>
    );
  };

  // eslint-disable-next-line react/no-multi-comp, react/display-name
  const renderButton = () => {
    return disabled ? null : (
      <div className={css.buttonWrapper}>
        <ActionButton
          text={i18n.t("fields.file_upload_box.select_file_button_text")}
          type={ACTION_BUTTON_TYPES.default}
          pending={file.loading}
          rest={{
            component: "span",
            variant: "outlined",
            disabled: disabled || fieldDisabled()
          }}
        />
      </div>
    );
  };

  return (
    <div className={clsx(css.attachment, { [css.document]: isDocument })}>
      <label htmlFor={name}>
        <InputLabel>{label}</InputLabel>
        <FormHelperText error={error}>{helperText}</FormHelperText>
        {renderButton()}
      </label>
      <div className={css.inputField}>
        <input
          type="file"
          id={name}
          name={name}
          onChange={handleChange}
          ref={register}
          disabled={disabled || fieldDisabled()}
          accept={acceptedTypes}
        />
        <input type="hidden" name={`${name}_base64`} ref={register} />
        <input type="hidden" name={`${name}_file_name`} ref={register} />
        <input type="hidden" name={`${name}_url`} ref={register} />
      </div>
      {renderPreview()}
    </div>
  );
};

AttachmentInput.displayName = "AttachmentInput";

AttachmentInput.propTypes = {
  commonInputProps: PropTypes.object,
  metaInputProps: PropTypes.object
};

export default AttachmentInput;
