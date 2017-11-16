LiveRecord.Model.create(
  {
    modelName: 'Post',
    belongsTo: {
      user: { foreignKey: 'user_id', modelName: 'User' },
      category: { foreignKey: 'category_id', modelName: 'Category' }
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
