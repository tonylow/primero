import React, { useEffect, useState, useRef } from "react";
import PropTypes from "prop-types";
import { useFormContext } from "react-hook-form";
import { useSelector } from "react-redux";

import { useI18n } from "../../i18n";
// TODO: REFACTOR AND MOVE THE FOLLOWING BELOW
import { FILTER_TYPES } from "../../index-filters";
import handleFilterChange from "../../index-filters/components/filter-types/value-handlers";
import { whichOptions, optionText, registerInput } from "../utils";
import { getOption } from "../../record-form";
import { CHECK_BOX_FIELD, SELECT_FIELD } from "../constants";

const inferDefaultValue = ({ type, multiSelect }) => {
  if (type === CHECK_BOX_FIELD || multiSelect) {
    return [];
  }

  return undefined;
};

const getTypeValueObject = (event, value, type) => {
  switch (type) {
    case FILTER_TYPES.TOGGLE:
      return { type: "basic", value: event?.target?.checked };
    case FILTER_TYPES.CHECKBOX:
    case CHECK_BOX_FIELD:
      return { type: "checkboxes" };
    default: {
      return { type: "basic", value };
    }
  }
};

const Input = ({ field, children }) => {
  const {
    options,
    field_name: fieldName,
    display_name: displayName,
    name,
    type,
    option_strings_source: optionStringsSource,
    option_strings_text: optionsStringsText,
    multi_select: multiSelect
  } = field;
  const i18n = useI18n();
  const { register, unregister, setValue, errors } = useFormContext();
  const defaultValue = inferDefaultValue({ type, multiSelect });
  const [inputValue, setInputValue] = useState(defaultValue);
  const valueRef = useRef();

  const inputName = name || fieldName;
  const inputError = errors?.[name]
  const lookups = useSelector(state =>
    getOption(state, optionStringsSource, i18n.locale)
  );

  const inputOptions = whichOptions({
    optionStringsSource,
    lookups,
    options: options || optionsStringsText,
    i18n
  });

  const handleChange = (event, value) => {
    const typeValueObject = getTypeValueObject(event, value, type);

    handleFilterChange({
      ...typeValueObject,
      event,
      setInputValue,
      inputValue,
      setValue,
      defaultValue,
      fieldName: inputName
    });
  };

  useEffect(() => {
    registerInput({
      register,
      name: inputName,
      ref: valueRef,
      setInputValue,
      dataSetter: data => {
        if (type === SELECT_FIELD) {
          return multiSelect ? data.map(d => d.id) : data?.id;
        }

        return data;
      }
    });

    return () => {
      unregister(fieldName);
    };
  }, [register, unregister, fieldName]);

  const inputProps = {
    handleChange,
    i18n,
    optionText,
    inputOptions,
    inputValue,
    ...(FILTER_TYPES.TOGGLE && {
      label: options ? options?.[i18n.locale]?.[0]?.display_name : displayName
    }),
    setValue,
    error: inputError?.message,
    hasError: typeof inputError !== "undefined"
  };

  return <div>{children(inputProps)}</div>;
};

Input.displayName = "Input";

Input.propTypes = {
  children: PropTypes.func.isRequired,
  field: PropTypes.object.isRequired
};

export default Input;
