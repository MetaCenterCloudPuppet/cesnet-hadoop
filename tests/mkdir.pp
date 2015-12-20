class{'::hadoop':
  realm => '',
}

hadoop::kinit{'test-kinit':
  touchfile => 'test_puppet_mkdir',
}
->
hadoop::mkdir{'/user/kirk':
  touchfile => 'test_puppet_mkdir',
}
->
hadoop::kdestroy{'test-kdestroy':
  touchfile => 'test_puppet_mkdir',
  touch     => true,
}
