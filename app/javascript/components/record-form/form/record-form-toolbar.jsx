import React from "react";
import PropTypes from "prop-types";
import { Box, IconButton, Fab } from "@material-ui/core";
import { withRouter, Link } from "react-router-dom";
import { makeStyles } from "@material-ui/styles";
import CreateIcon from "@material-ui/icons/Create";

import { useI18n } from "./../../i18n";
import { Flagging } from "./../../flagging";
import RecordActions from "./../../record-actions";
import Permission from "./../../application/permission";

import { WorkflowIndicator } from "./components";
import styles from "./styles.css";

const RecordFormToolbar = ({
  mode,
  params,
  recordType,
  handleFormSubmit,
  shortId,
  history,
  primeroModule,
  record
}) => {
  const css = makeStyles(styles)();
  const i18n = useI18n();

  const PageHeading = () => {
    let heading = "";

    if (mode.isNew) {
      heading = i18n.t(`${params.recordType}.register_new_${recordType}`);
    } else if (mode.isEdit || mode.isShow) {
      heading = i18n.t(`${params.recordType}.show_${recordType}`, {
        short_id: shortId || "-------"
      });
    }
    return <h2 className={css.toolbarHeading}>{heading}</h2>;
  };

  const goBack = () => {
    history.goBack();
  };

  return (
    <Box
      className={css.toolbar}
      width="100%"
      px={2}
      mb={3}
      display="flex"
      alignItems="center"
    >
      <Box flexGrow={1} display="flex" flexDirection="column">
        <PageHeading />
        {(mode.isShow || mode.isEdit) && params.recordType === "cases" && (
          <WorkflowIndicator
            locale={i18n.locale}
            primeroModule={primeroModule}
            recordType={params.recordType}
            record={record}
          />
        )}
      </Box>
      <Box>
        {mode.isShow && params && (
          <Permission
            recordType={params.recordType}
            permission={["flag", "manage"]}
          >
            <Flagging recordType={params.recordType} record={params.id} />
          </Permission>
        )}
        {(mode.isEdit || mode.isNew) && (
          <>
            <Fab
              className={css.actionButtonCancel}
              variant="extended"
              aria-label={i18n.t("buttons.cancel")}
              onClick={goBack}
            >
              {i18n.t("buttons.cancel")}
            </Fab>
            <Fab
              className={css.actionButton}
              variant="extended"
              aria-label={i18n.t("buttons.save")}
              onClick={handleFormSubmit}
            >
              {i18n.t("buttons.save")}
            </Fab>
          </>
        )}
        {mode.isShow && (
          <Permission
            recordType={params.recordType}
            permission={["write", "manage"]}
          >
            <IconButton
              to={`/${params.recordType}/${params.id}/edit`}
              component={Link}
            >
              <CreateIcon />
            </IconButton>
          </Permission>
        )}
        <RecordActions
          recordType={params.recordType}
          record={record}
          mode={mode}
        />
      </Box>
    </Box>
  );
};

RecordFormToolbar.propTypes = {
  mode: PropTypes.object,
  params: PropTypes.object.isRequired,
  recordType: PropTypes.string.isRequired,
  handleFormSubmit: PropTypes.func.isRequired,
  shortId: PropTypes.string,
  history: PropTypes.object,
  primeroModule: PropTypes.string.isRequired,
  record: PropTypes.object
};

export default withRouter(RecordFormToolbar);