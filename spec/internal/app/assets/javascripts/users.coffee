LiveRecord.Model.create(
  {
    modelName: 'User',
    hasMany: {
      posts: { foreignKey: 'user_id', modelName: 'Post' }
    },
    plugins: {
      LiveDOM: true
    }
  }
)
