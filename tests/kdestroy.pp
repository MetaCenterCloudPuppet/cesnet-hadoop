class{'::hadoop':
  realm => '',
}
hadoop::kdestroy{'my-kdestroy':
  touchfile => 'my_touch_file',
  touch     => true,
}
