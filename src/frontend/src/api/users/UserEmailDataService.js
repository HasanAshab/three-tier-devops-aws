import axios from "../customAxiosConfig/CustomAxiosConfig";

const UserEmailDataService = async (email) => {
  try {
    return axios.post(`/notification`, null, {
      params: {
        email,
      },
    });
  } catch (err) {
    let error = "";
    if (err.response) {
      error += err.response;
    }
    return error;
  }
};

export default UserEmailDataService;
