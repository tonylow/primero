import { loadApplicationResources } from "components/application";
import { batch } from "react-redux";
import * as Actions from "./actions";

export const setUser = payload => {
  return {
    type: Actions.SET_AUTHENTICATED_USER,
    payload
  };
};

export const fetchAuthenticatedUserData = id => async dispatch => {
  dispatch({
    type: Actions.FETCH_USER_DATA,
    api: {
      path: `users/${id}`,
      params: {
        extended: true
      }
    }
  });
};

export const setAuthenticatedUser = user => async dispatch => {
  await dispatch(setUser(user));

  batch(() => {
    dispatch(fetchAuthenticatedUserData(user.id));
    dispatch(loadApplicationResources());
  });
};

export const attemptSignout = () => async dispatch => {
  dispatch({
    type: Actions.LOGOUT,
    api: {
      path: "tokens",
      method: "DELETE",
      successCallback: Actions.LOGOUT_SUCCESS_CALLBACK
    }
  });
};

export const checkUserAuthentication = () => async dispatch => {
  const user = JSON.parse(localStorage.getItem("user"));

  if (user) {
    dispatch(setAuthenticatedUser(user));
  }
};