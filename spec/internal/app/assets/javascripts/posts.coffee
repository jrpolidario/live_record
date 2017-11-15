LiveRecord.Model.create(
  {
    modelName: 'Post',
    belongsTo: {
      user: { foreignKey: 'user_id', modelName: 'User' }
    },
    plugins: {
      LiveDOM: true
    },
    classMethods: {
    },
    instanceMethods: {
    }
  }
)
