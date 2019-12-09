import React, { useEffect, useState, useRef } from "react";
import PropTypes from "prop-types";
import { useFormContext } from "react-hook-form";
import {
  FormGroup,
  FormControlLabel,
  FormControl,
  Checkbox
} from "@material-ui/core";
import { useSelector } from "react-redux";

import Panel from "../panel";
import { getOption } from "../../../record-form";
import { useI18n } from "../../../i18n";

import { registerInput, whichOptions, optionText } from "./utils";
import handleFilterChange, { getFilterProps } from "./value-handlers";

const CheckboxFilter = ({ filter }) => {
  const i18n = useI18n();
  const { register, unregister, setValue, user, getValues } = useFormContext();
  const valueRef = useRef();
  const [inputValue, setInputValue] = useState([]);
  const { options, fieldName, optionStringsSource, isObject } = getFilterProps({
    filter,
    user,
    i18n
  });

  useEffect(() => {
    registerInput({
      register,
      name: fieldName,
      ref: valueRef,
      defaultValue: isObject ? {} : [],
      setInputValue
    });

    return () => {
      unregister(fieldName);
    };
  }, [register, unregister, fieldName]);

  const lookups = useSelector(state =>
    getOption(state, optionStringsSource, i18n.locale)
  );

  const filterOptions = whichOptions({
    optionStringsSource,
    lookups,
    options,
    i18n
  });

  const handleChange = event =>
    handleFilterChange({
      type: isObject ? "objectCheckboxes" : "checkboxes",
      event,
      setInputValue,
      inputValue,
      setValue,
      fieldName
    });

  const handleReset = () => {
    const value = isObject ? {} : [];

    setValue(fieldName, value);
  };

  const renderOptions = () =>
    filterOptions.map(option => {
      return (
        <FormControlLabel
          key={`${fieldName}-${option.id}`}
          control={
            <Checkbox
              onChange={handleChange}
              value={option.id}
              checked={
                isObject
                  ? option.key in inputValue
                  : inputValue.includes(option.id)
              }
            />
          }
          label={optionText(option, i18n)}
        />
      );
    });

  return (
    <Panel filter={filter} getValues={getValues} handleReset={handleReset}>
      <FormControl component="fieldset">
        <FormGroup>{renderOptions()}</FormGroup>
      </FormControl>
    </Panel>
  );
};

CheckboxFilter.displayName = "CheckboxFilter";

CheckboxFilter.propTypes = {
  filter: PropTypes.object.isRequired
};

export default CheckboxFilter;
