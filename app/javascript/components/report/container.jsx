import React, { useEffect } from "react";
import { useSelector, useDispatch } from "react-redux";
import PropTypes from "prop-types";
import { Paper, Typography } from "@material-ui/core";
import { push } from "connected-react-router";
import { useLocation, useParams } from "react-router-dom";
import CreateIcon from "@material-ui/icons/Create";
import DeleteIcon from "@material-ui/icons/Delete";
import makeStyles from "@material-ui/core/styles/makeStyles";

import { BarChart as BarChartGraphic, TableValues } from "../charts";
import { getLoading, getErrors } from "../index-table/selectors";
import LoadingIndicator from "../loading-indicator";
import { useI18n } from "../i18n";
import PageContainer, { PageContent, PageHeading } from "../page";
import { FormAction, whichFormMode } from "../form";
import { usePermissions } from "../user";
import { WRITE_RECORDS, MANAGE } from "../../libs/permissions";
import ActionDialog, { useDialog } from "../action-dialog";
import { getOptions } from "../form/selectors";
import { STRING_SOURCES_TYPES } from "../../config";

import { buildDataForGraph, buildDataForTable } from "./utils";
import { getReport } from "./selectors";
import { deleteReport, fetchReport } from "./action-creators";
import namespace from "./namespace";
import { NAME, DELETE_MODAL } from "./constants";
import Exporter from "./components/exporter";
import styles from "./styles.css";

// const { dialogOpen, setDialog } = useDialog(DELETE_MODAL);

const Report = ({ mode }) => {
  const { id } = useParams();
  const i18n = useI18n();
  const dispatch = useDispatch();
  const formMode = whichFormMode(mode);
  const { pathname } = useLocation();
  const { setDialog, dialogOpen, dialogClose, pending, setDialogPending } = useDialog(DELETE_MODAL);
  const css = makeStyles(styles)();

  useEffect(() => {
    dispatch(fetchReport(id));
  }, []);

  const errors = useSelector(state => getErrors(state, namespace));
  const loading = useSelector(state => getLoading(state, namespace));
  const report = useSelector(state => getReport(state));
  const name = report.getIn(["name", i18n.locale], "");
  const description = report.getIn(["description", i18n.locale], "");
  const agencies = useSelector(state => getOptions(state, STRING_SOURCES_TYPES.AGENCY, i18n, null, true));

  const setDeleteModal = open => {
    setDialog({ dialog: DELETE_MODAL, open });
  };

  const loadingIndicatorProps = {
    overlay: true,
    emptyMessage: i18n.t("report.no_data"),
    hasData: !!report.get("report_data", false),
    type: namespace,
    loading,
    errors
  };

  const canEditReport = usePermissions(namespace, WRITE_RECORDS) && report.get("editable");

  const canDeleteReport = usePermissions(namespace, MANAGE) && report.get("editable");

  const handleEdit = () => {
    dispatch(push(`${pathname}/edit`));
  };

  const handleDelete = () => {
    setDialogPending(true);

    dispatch(
      deleteReport({
        id,
        message: i18n.t("report.messages.delete_success")
      })
    );
  };

  const editButton = formMode.get("isShow") && canEditReport && (
    <FormAction actionHandler={handleEdit} text={i18n.t("buttons.edit")} startIcon={<CreateIcon />} />
  );

  const cancelButton = formMode.get("isShow") && canDeleteReport && (
    <FormAction
      actionHandler={() => setDeleteModal(true)}
      cancel
      text={i18n.t("buttons.delete")}
      startIcon={<DeleteIcon />}
    />
  );

  const reportDescription = description ? <h4 className={css.description}>{description}</h4> : null;

  return (
    <PageContainer>
      <PageHeading title={name}>
        <Exporter includesGraph={report.get("graph")} />
        {cancelButton}
        {editButton}
      </PageHeading>
      <PageContent>
        <LoadingIndicator {...loadingIndicatorProps}>
          {reportDescription}
          {report.get("graph") && (
            <Paper>
              <BarChartGraphic {...buildDataForGraph(report, i18n, { agencies })} showDetails />
            </Paper>
          )}
          <TableValues {...buildDataForTable(report, i18n, { agencies })} />
        </LoadingIndicator>
        <ActionDialog
          open={dialogOpen}
          dialogTitle={i18n.t("reports.delete_report")}
          successHandler={() => handleDelete()}
          cancelHandler={() => dialogClose()}
          omitCloseAfterSuccess
          maxSize="xs"
          pending={pending}
          confirmButtonLabel={i18n.t("buttons.ok")}
        >
          <Typography color="textSecondary">{i18n.t("reports.delete_report_message")}</Typography>
        </ActionDialog>
      </PageContent>
    </PageContainer>
  );
};

Report.displayName = NAME;

Report.propTypes = {
  mode: PropTypes.string.isRequired
};

export default Report;
