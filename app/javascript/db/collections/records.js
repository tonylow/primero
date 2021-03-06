import DB from "../db";

const Records = {
  find: async ({ collection, recordType, db }) => {
    const { id } = db;

    return {
      data: id ? await DB.getRecord(collection, id) : await DB.getAllFromIndex(collection, "type", recordType)
    };
  },

  save: async ({ collection, json, recordType }) => {
    const { data, metadata } = json;
    const dataIsArray = Array.isArray(data);
    const recordData = Array.isArray(data) ? data : { ...data, complete: true };

    if (dataIsArray) {
      await DB.bulkAdd(collection, recordData, {
        index: "type",
        value: recordType
      });
    } else {
      await DB.put(collection, recordData, null, {
        index: "type",
        value: recordType
      });
    }

    const recordDB = data.id && !dataIsArray && (await DB.getRecord(collection, data.id));

    return {
      data: recordDB || recordData,
      ...(dataIsArray && { metadata })
    };
  },

  onTransaction: async ({ collection, db, transactionCallback }) => {
    const result = await DB.onTransaction(collection, db.mode, transactionCallback);

    return { data: result };
  }
};

export default Records;
