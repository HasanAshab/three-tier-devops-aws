import axios from "../../customAxiosConfig/CustomAxiosConfig";

const UpdatePasswordService = (id, password) => {
  try {
    return axios.put(`/password`, null, {
      params: {
        id,
        password,
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

export default UpdatePasswordService;
