import { fromJS } from "immutable";
import { describe } from "mocha";

import { RECORD_TYPES } from "../../config";
import { GROUP_PERMISSIONS, ACTIONS } from "../../libs/permissions";

import * as selectors from "./selectors";

const agencyWithLogo = {
  unique_id: "agency-unicef",
  name: "UNICEF",
  logo: {
    small: "/rails/active_storage/blobs/jeff.png"
  }
};

const agency1 = {
  unique_id: "agency-test-1",
  agency_code: "test1",
  disabled: false,
  services: ["service_test_1"]
};

const agency2 = {
  unique_id: "agency-test-2",
  agency_code: "test2",
  disabled: false,
  services: ["service_test_1", "service_test_2"]
};

const agency3 = {
  unique_id: "agency-test-3",
  agency_code: "test3",
  disabled: true,
  services: ["service_test_1"]
};

const userGroups = [
  { id: 1, unique_id: "user-group-1" },
  { id: 2, unique_id: "user-group-2" }
];

const roles = [
  { id: 1, unique_id: "role-1", name: "Role 1" },
  { id: 2, unique_id: "role-2", name: "Role 2" }
];

const stateWithNoRecords = fromJS({});
const stateWithRecords = fromJS({
  application: {
    primero: {
      sandbox_ui: true
    },
    userIdle: true,
    agencies: [agencyWithLogo, agency1, agency2, agency3],
    modules: [
      {
        unique_id: "primeromodule-cp",
        name: "CP",
        associated_record_types: ["case", "tracing_request", "incident"],
        options: {
          allow_searchable_ids: true,
          use_workflow_case_plan: true,
          use_workflow_assessment: false,
          reporting_location_filter: true,
          use_workflow_service_implemented: true
        }
      },
      {
        unique_id: "primeromodule-gbv",
        name: "GBV",
        associated_record_types: ["case", "incident"],
        options: {
          user_group_filter: true
        }
      }
    ],
    reportingLocationConfig: {
      field_key: "owned_by_location",
      admin_level: 2,
      admin_level_map: { 1: ["province"], 2: ["district"] },
      label_keys: ["district"]
    },
    permissions: fromJS({
      management: [GROUP_PERMISSIONS.SELF],
      resource_actions: { case: [ACTIONS.READ] }
    }),
    locales: ["en", "fr", "ar"],
    defaultLocale: "en",
    baseLanguage: "en",
    primeroVersion: "2.0.0.1",
    approvalsLabels: {
      closure: {
        en: "Closure",
        fr: "",
        ar: "Closure-AR"
      },
      case_plan: {
        en: "Case Plan",
        fr: "",
        ar: "Case Plan-AR"
      },
      assessment: {
        en: "Assessment",
        fr: "",
        ar: "Assessment-AR"
      },
      action_plan: {
        en: "Action Plan",
        fr: "",
        ar: "Action Plan-AR"
      },
      gbv_closure: {
        en: "GBV Closure",
        fr: "",
        ar: "GBV Closure-AR"
      }
    },
    userGroups,
    roles,
    disabledApplication: true
  }
});

describe("Application - Selectors", () => {
  describe("selectAgencies", () => {
    it("should return records", () => {
      const expected = fromJS([agencyWithLogo, agency1, agency2, agency3]);

      const records = selectors.selectAgencies(stateWithRecords);

      expect(records).to.deep.equal(expected);
    });

    it("should return empty object when records empty", () => {
      const records = selectors.selectAgencies(stateWithNoRecords);

      expect(records).to.be.empty;
    });
  });

  describe("selectModules", () => {
    it("should return records", () => {
      const expected = fromJS([
        {
          unique_id: "primeromodule-cp",
          name: "CP",
          associated_record_types: ["case", "tracing_request", "incident"],
          options: {
            allow_searchable_ids: true,
            use_workflow_case_plan: true,
            use_workflow_assessment: false,
            reporting_location_filter: true,
            use_workflow_service_implemented: true
          }
        },
        {
          unique_id: "primeromodule-gbv",
          name: "GBV",
          associated_record_types: ["case", "incident"],
          options: {
            user_group_filter: true
          }
        }
      ]);

      const records = selectors.selectModules(stateWithRecords);

      expect(records).to.deep.equal(expected);
    });

    it("should return empty object when records empty", () => {
      const records = selectors.selectModules(stateWithNoRecords);

      expect(records).to.be.empty;
    });
  });

  describe("selectLocales", () => {
    it("should return records", () => {
      const expected = fromJS(["en", "fr", "ar"]);

      const records = selectors.selectLocales(stateWithRecords);

      expect(records).to.deep.equal(expected);
    });

    it("should return empty object when records empty", () => {
      const records = selectors.selectLocales(stateWithNoRecords);

      expect(records).to.be.empty;
    });
  });

  describe("selectUserIdle", () => {
    it("should return weither user is idle", () => {
      const selector = selectors.selectUserIdle(stateWithRecords);

      expect(selector).to.equal(true);
    });
  });

  describe("getReportingLocationConfig", () => {
    it("should return the reporting location config", () => {
      const selector = selectors.getReportingLocationConfig(stateWithRecords);
      const config = fromJS({
        admin_level: 2,
        field_key: "owned_by_location",
        admin_level_map: { 1: ["province"], 2: ["district"] },
        label_keys: ["district"]
      });

      expect(selector).to.deep.equal(config);
    });
  });

  describe("getSystemPermissions", () => {
    it("should return the system permissions", () => {
      const selector = selectors.getSystemPermissions(stateWithRecords);
      const permissions = fromJS({
        management: [GROUP_PERMISSIONS.SELF],
        resource_actions: { case: [ACTIONS.READ] }
      });

      expect(selector).to.deep.equal(permissions);
    });
  });

  describe("getResourceActions", () => {
    it("should return the resource actions", () => {
      const selector = selectors.getResourceActions(stateWithRecords, RECORD_TYPES.cases);

      expect(selector).to.deep.equal(fromJS([ACTIONS.READ]));
    });
  });

  describe("getEnabledAgencies", () => {
    it("should return the enabled agencies", () => {
      const expected = fromJS([agencyWithLogo, agency1, agency2]);
      const enabledAgencies = selectors.getEnabledAgencies(stateWithRecords);

      expect(enabledAgencies).to.deep.equal(expected);
    });

    it("should return enabled agencies with the selected service", () => {
      const expected = fromJS([agency2]);
      const agenciesWithService = selectors.getEnabledAgencies(stateWithRecords, "service_test_2");

      expect(agenciesWithService).to.deep.equal(expected);
    });

    it("should return empty if there are no agencies with the selected service", () => {
      const agenciesWithService = selectors.getEnabledAgencies(stateWithRecords, "service_test_5");

      expect(agenciesWithService).to.be.empty;
    });

    it("should return empty if there are no enabled agencies", () => {
      const enabledAgencies = selectors.getEnabledAgencies(stateWithNoRecords);

      expect(enabledAgencies).to.be.empty;
    });
  });

  describe("getApprovalsLabels", () => {
    it("should return the approvalsLabels", () => {
      const expectedApprovalsLabels = {
        closure: "Closure",
        case_plan: "Case Plan",
        assessment: "Assessment",
        action_plan: "Action Plan",
        gbv_closure: "GBV Closure"
      };
      const approvalsLabels = selectors.getApprovalsLabels(stateWithRecords, "en");

      expect(approvalsLabels).to.deep.equal(expectedApprovalsLabels);
    });
  });

  describe("getUserGroups", () => {
    it("should return user groups", () => {
      expect(selectors.getUserGroups(stateWithRecords)).to.deep.equal(fromJS(userGroups));
    });
  });

  describe("getRoles", () => {
    it("should return roles", () => {
      expect(selectors.getRoles(stateWithRecords)).to.deep.equal(fromJS(roles));
    });
  });

  describe("getRoleName", () => {
    it("should return the role name", () => {
      expect(selectors.getRoleName(stateWithRecords, "role-2")).to.deep.equal("Role 2");
    });
  });

  describe("getDisabledApplication", () => {
    it("should return boolean value that identifies if the application is disabled or not", () => {
      expect(selectors.getDisabledApplication(stateWithRecords)).to.be.true;
    });
  });

  describe("getDemo", () => {
    it("should return the role name", () => {
      expect(selectors.getDemo(stateWithRecords)).to.be.true;
    });
  });

  describe("getAdminLevel", () => {
    it("should return the admin_level", () => {
      const selector = selectors.getAdminLevel(stateWithRecords);

      expect(selector).to.be.equal(2);
    });
  });
});
