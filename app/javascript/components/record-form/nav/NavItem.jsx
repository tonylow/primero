import React from "react";
import PropTypes from "prop-types";
import { ListItem, ListItemText } from "@material-ui/core";
import ExpandLess from "@material-ui/icons/ExpandLess";
import ExpandMore from "@material-ui/icons/ExpandMore";
import { makeStyles } from "@material-ui/styles";
import isEmpty from "lodash/isEmpty";

import { Jewel } from "../../jewel";

import styles from "./styles.css";
import { NAV_ITEM } from "./constants";

const NavItem = ({
  form,
  isNested,
  open,
  handleClick,
  selectedForm,
  groupItem,
  name,
  recordAlerts,
  itemsOfGroup
}) => {
  const css = makeStyles(styles)();

  const { formId, group } = form;

  const handlerArgs = {
    formId,
    group: isNested ? group : false,
    parentItem: isNested
  };

  const formsWithAlerts =
    recordAlerts?.size &&
    [...recordAlerts.map(alert => alert.get("form_unique_id"))].filter(
      alert => !isEmpty(alert)
    );

  let showJewel = false;

  if (isNested) {
    showJewel = itemsOfGroup?.some(alert => formsWithAlerts?.includes(alert));
  } else {
    showJewel = formsWithAlerts?.includes(formId);
  }

  const formText = showJewel ? <Jewel value={name} isForm /> : name;

  return (
    <ListItem
      selected={selectedForm === formId && !isNested}
      button
      key={formId}
      onClick={() => handleClick(handlerArgs)}
      classes={{
        selected: css.navSelected,
        root: css.root
      }}
    >
      <ListItemText className={groupItem ? css.nestedItem : css.item}>
        {formText}
      </ListItemText>
      {isNested && (open ? <ExpandMore /> : <ExpandLess />)}
    </ListItem>
  );
};

NavItem.displayName = NAV_ITEM;

NavItem.propTypes = {
  form: PropTypes.object,
  groupItem: PropTypes.bool,
  handleClick: PropTypes.func,
  isNested: PropTypes.bool,
  itemsOfGroup: PropTypes.array,
  name: PropTypes.string,
  open: PropTypes.bool,
  recordAlerts: PropTypes.object,
  selectedForm: PropTypes.oneOfType([PropTypes.string, PropTypes.number])
};

export default NavItem;
